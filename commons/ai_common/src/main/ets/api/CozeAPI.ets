/**
 * Copyright (c) 2025 XBXyftx
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { rcp } from '@kit.RemoteCommunicationKit'
import { util } from '@kit.ArkTS'
import { BusinessError } from '@kit.BasicServicesKit'
import { AppStorageV2 } from '@kit.ArkUI'
import {
  AIModelType,
  AI_WORKFLOW_CONFIG,
  AI_STORAGE_KEYS,
  AI_LOG_TAG,
  MessageRole
} from '../modules/enums'
import { CozeApiConfig } from '../modules/constants'
import {
  ICozeRequestBody,
  ICozeStreamDeltaData,
  ViewMessageModel,
  MessageHistoryList,
  WaitingResponseState,
  AIErrorState
} from '../modules/models'
import { typeStringBuffer } from '../utils/TypeStringBuffer'
import { aiLogger } from '../utils/AILogger'

/**
 * Coze API 授权令牌
 * TODO: 替换为实际的 API Token
 */
const COZE_AUTH_TOKEN: string = 'Bearer pat_OjbCtDedMN0L9BItNljPmHu8uuxsSZiLxHoahXpMlJtGRzuilLKfbjLBa77iqcjs'

/**
 * Coze API 服务类
 * 
 * 负责与扣子平台进行流式对话通信
 */
export class CozeAPIService {
  private session: rcp.Session | null = null

  /**
   * 处理流式数据
   */
  private handleStreamData(incomingData: ArrayBuffer, currentMsg: ViewMessageModel): void {
    currentMsg.hasEnd = false
    const bufferFrom = new Uint8Array(incomingData)
    const dataStr = new util.TextDecoder().decodeToString(bufferFrom)
    
    aiLogger.info(`${AI_LOG_TAG.COZE_API}收到流式数据: ${dataStr.substring(0, 100)}...`)

    const lines: string[] = dataStr.split('\n')
    const deltaDataLines: number[] = []
    typeStringBuffer.rcpEnd = false

    try {
      // 找出包含消息增量的行
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('conversation.message.delta')) {
          deltaDataLines.push(i + 1)
        }
      }

      // 解析消息增量数据
      for (let i = 0; i < lines.length; i++) {
        if (deltaDataLines.includes(i)) {
          const parts: string[] = lines[i].split('data: ')
          if (parts.length > 1) {
            const dataPart = parts[1]
            try {
              const deltaData: ICozeStreamDeltaData = JSON.parse(dataPart) as ICozeStreamDeltaData
              let messageContent: string = ''
              if (deltaData.content) {
                messageContent = deltaData.content.replace('null', '')
              }
              if (messageContent !== '') {
                aiLogger.debug(`${AI_LOG_TAG.COZE_API}解析到消息内容: ${messageContent}`)
                typeStringBuffer.strAdd(messageContent)
                typeStringBuffer.start()
              }
            } catch (parseErr) {
              aiLogger.warn(`${AI_LOG_TAG.COZE_API}解析JSON失败: ${parseErr}`)
            }
          }
        }
      }
    } catch (err) {
      aiLogger.error(`${AI_LOG_TAG.COZE_API}处理流式数据异常: ${err}`)
    }
  }

  /**
   * 发送对话请求
   * 
   * @param conversationId - 会话ID
   * @param modelType - AI模型类型
   * @param messageList - 消息历史列表
   * @param currentMsg - 当前正在接收的消息对象
   * @returns Promise<boolean> - 请求是否成功发送
   */
  async sendMessage(
    conversationId: string,
    modelType: AIModelType,
    messageList: MessageHistoryList,
    currentMsg: ViewMessageModel
  ): Promise<boolean> {
    if (modelType === AIModelType.NOT_SELECTED) {
      aiLogger.error(`${AI_LOG_TAG.COZE_API}未选择AI模型类型`)
      return false
    }

    const workflowId: string = AI_WORKFLOW_CONFIG.get(modelType) || ''
    if (workflowId === '') {
      aiLogger.error(`${AI_LOG_TAG.COZE_API}未配置 workflow_id: ${modelType}`)
      return false
    }

    // 构建请求参数
    const parameters: Record<string, string> = {}
    parameters['CONVERSATION_NAME'] = `HXY_${conversationId}`

    // 构建请求体
    const requestBody: ICozeRequestBody = {
      workflow_id: workflowId,
      additional_messages: messageList.getCozeMessages(),
      parameters: parameters,
      conversation_id: conversationId
    }

    aiLogger.info(`${AI_LOG_TAG.COZE_API}发送请求: conversationId=${conversationId}, modelType=${modelType}`)

    try {
      // 创建 session 配置
      const sessionConfig: rcp.SessionConfiguration = {
        headers: {
          'Authorization': COZE_AUTH_TOKEN,
          'Content-Type': CozeApiConfig.CONTENT_TYPE
        },
        requestConfiguration: {
          transfer: {
            timeout: {
              transferMs: CozeApiConfig.TIMEOUT_MS
            }
          },
          tracing: {
            httpEventsHandler: {
              onDataReceive: (incomingData: ArrayBuffer) => {
                this.handleStreamData(incomingData, currentMsg)
              }
            }
          }
        }
      }

      // 创建 session
      this.session = rcp.createSession(sessionConfig)

      // 发送 POST 请求
      await this.session.post(CozeApiConfig.WORKFLOW_CHAT_URL, requestBody)
        .catch((err: BusinessError) => {
          aiLogger.error(`${AI_LOG_TAG.COZE_API}请求失败: ${err.message}`)
          this.setErrorState(`网络请求失败: ${err.message}`)
        })
        .finally(() => {
          this.handleRequestComplete(currentMsg, messageList)
        })

      return true
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.COZE_API}发送请求异常: ${err.message}`)
      this.setErrorState(`发送请求异常: ${err.message}`)
      return false
    }
  }

  /**
   * 处理请求完成
   */
  private handleRequestComplete(
    currentMsg: ViewMessageModel,
    messageList: MessageHistoryList
  ): void {
    typeStringBuffer.rcpEnd = true
    aiLogger.info(`${AI_LOG_TAG.COZE_API}流式传输结束，开始写入历史记录`)

    // 将AI回复添加到历史记录
    const assistantMessage = new ViewMessageModel(MessageRole.Assistant, currentMsg.content)
    assistantMessage.hasEnd = true
    messageList.addMessage(assistantMessage)

    aiLogger.info(`${AI_LOG_TAG.COZE_API}历史记录添加完毕`)

    // 关闭 session
    if (this.session !== null) {
      this.session.close()
      this.session = null
      aiLogger.info(`${AI_LOG_TAG.COZE_API}Session 已关闭`)
    }

    // 更新等待状态
    const waitingState = AppStorageV2.connect(
      WaitingResponseState,
      AI_STORAGE_KEYS.IS_WAITING_RESPONSE,
      () => new WaitingResponseState()
    )
    if (waitingState !== undefined) {
      waitingState.isWaiting = false
    }
  }

  /**
   * 取消当前请求
   */
  cancelRequest(): void {
    if (this.session !== null) {
      this.session.close()
      this.session = null
      aiLogger.info(`${AI_LOG_TAG.COZE_API}请求已取消`)
    }
  }

  /**
   * 设置错误状态
   */
  private setErrorState(message: string): void {
    const errorState = AppStorageV2.connect(
      AIErrorState,
      AI_STORAGE_KEYS.ERROR_STATE,
      () => new AIErrorState()
    )
    if (errorState !== undefined) {
      errorState.setError(message)
    }
  }
}

/** Coze API 服务单例 */
export const cozeAPI: CozeAPIService = new CozeAPIService()
