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

import { AppStorageV2 } from '@kit.ArkUI'
import { AI_STORAGE_KEYS, AI_LOG_TAG } from '../modules/enums'
import { TypewriterConfig } from '../modules/constants'
import { ViewMessageModel } from '../modules/models'
import { aiLogger } from './AILogger'

/**
 * 打字机效果的数据接收缓冲区
 * 
 * 用于实现流式响应的打字机效果，逐字符显示AI回复
 */
@ObservedV2
class TypeStringBuffer {
  /** 启动标识符 */
  private startSign: boolean = false
  /** 待输出字符串数组 */
  private charArray: string[] = []
  /** 当前轮次流式传输结束标识符 */
  public rcpEnd: boolean = true
  /** 当前正在接收的消息对象 */
  private currentMsg: ViewMessageModel | null = null

  /**
   * 设置当前消息对象
   */
  setCurrentMessage(msg: ViewMessageModel): void {
    this.currentMsg = msg
  }

  /**
   * 获取当前消息对象
   */
  getCurrentMessage(): ViewMessageModel | null {
    if (this.currentMsg === null) {
      const connected = AppStorageV2.connect(
        ViewMessageModel,
        AI_STORAGE_KEYS.CURRENT_RECEIVING_MESSAGE,
        () => new ViewMessageModel()
      )
      if (connected !== undefined) {
        this.currentMsg = connected
      }
    }
    return this.currentMsg
  }

  /**
   * 向缓冲区添加字符串
   */
  strAdd(addStr: string): void {
    if (addStr === '') {
      aiLogger.warn(`${AI_LOG_TAG.MESSAGE_BUFFER}strAdd: 字符串为空`)
      return
    }
    
    aiLogger.debug(`${AI_LOG_TAG.MESSAGE_BUFFER}strAdd: 添加字符串 ${addStr}`)
    
    for (let i = 0; i < addStr.length; i++) {
      this.charArray.push(addStr.charAt(i))
    }
  }

  /**
   * 启动打字机效果
   */
  start(): void {
    if (this.startSign) {
      aiLogger.debug(`${AI_LOG_TAG.MESSAGE_BUFFER}start: 已经在执行中`)
      return
    }

    this.startSign = true
    
    setTimeout(() => {
      const intervalId = setInterval(() => {
        const currentMsg = this.getCurrentMessage()
        if (currentMsg === null) {
          clearInterval(intervalId)
          this.startSign = false
          return
        }

        if (this.charArray.length > 0) {
          // 取出并删除第一个字符
          const currentChar = this.charArray.shift()
          if (currentChar !== undefined) {
            aiLogger.debug(`${AI_LOG_TAG.MESSAGE_BUFFER}输出字符: ${currentChar}`)
            currentMsg.content += currentChar
          }
        } else if (this.charArray.length === 0 && !this.rcpEnd) {
          // 缓冲区为空但流式传输未结束，等待更多数据
          aiLogger.debug(`${AI_LOG_TAG.MESSAGE_BUFFER}缓冲区为空，等待更多数据`)
        } else if (this.rcpEnd && this.charArray.length === 0) {
          // 流式传输结束且缓冲区已清空
          clearInterval(intervalId)
          this.startSign = false
          aiLogger.info(`${AI_LOG_TAG.MESSAGE_BUFFER}所有字符已输出完成`)
          currentMsg.hasEnd = true
        }
      }, TypewriterConfig.CHAR_INTERVAL_MS)
    }, TypewriterConfig.START_DELAY_MS)
  }

  /**
   * 重置缓冲区
   */
  reset(): void {
    this.charArray = []
    this.startSign = false
    this.rcpEnd = true
    this.currentMsg = null
    aiLogger.info(`${AI_LOG_TAG.MESSAGE_BUFFER}缓冲区已重置`)
  }
}

export const typeStringBuffer = new TypeStringBuffer()
