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
import { common } from '@kit.AbilityKit'
import { distributedKVStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import {
  AIModelType,
  AI_STORAGE_KEYS,
  AI_KV_DB_KEYS,
  AI_LOG_TAG,
  MessageRole,
  ViewMessageModel,
  MessageHistoryList,
  ConversationRecord,
  ConversationHistoryList,
  WaitingResponseState,
  CurrentModelTypeState,
  cozeAPI,
  typeStringBuffer,
  aiLogger,
  AI_KV_DB_ID
} from 'ai_common'

/**
 * 生成唯一会话ID
 */
function generateConversationId(): string {
  const timestamp = Date.now()
  const randomPart = Math.floor(Math.random() * 1000000).toString()
  return `conv_${timestamp}_${randomPart}`
}

/**
 * 聊天管理器
 * 
 * 负责管理整个AI对话流程，包括：
 * - 会话创建与管理
 * - 消息发送与接收
 * - 历史记录持久化
 */
export class ChatManager {
  /** KV数据库实例 */
  private kvStore: distributedKVStore.SingleKVStore | null = null
  /** 当前会话ID */
  private currentConversationId: string = ''
  /** 当前会话是否有实质性内容 */
  private hasSubstantialContent: boolean = false

  /**
   * 初始化聊天管理器
   */
  async init(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const kvManager: distributedKVStore.KVManager = distributedKVStore.createKVManager({
        context: context,
        bundleName: context.abilityInfo.bundleName
      })

      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: false,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      }

      this.kvStore = await kvManager.getKVStore(AI_KV_DB_ID, options) as distributedKVStore.SingleKVStore
      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}初始化成功`)
      
      // 加载会话历史列表
      await this.loadConversationHistory()
      
      return true
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}初始化失败: ${err.message}`)
      return false
    }
  }

  /**
   * 重置所有状态
   * 在创建新会话或加载历史会话前调用
   */
  resetAllStates(): void {
    // 取消当前正在进行的请求
    cozeAPI.cancelRequest()

    // 重置消息列表
    const messageList = AppStorageV2.connect(
      MessageHistoryList,
      AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
      () => new MessageHistoryList()
    )
    if (messageList !== undefined) {
      messageList.clear()
    }

    // 重置当前接收消息
    const currentMsg = AppStorageV2.connect(
      ViewMessageModel,
      AI_STORAGE_KEYS.CURRENT_RECEIVING_MESSAGE,
      () => new ViewMessageModel()
    )
    if (currentMsg !== undefined) {
      currentMsg.content = ''
      currentMsg.hasEnd = true
    }

    // 重置等待状态
    const waitingState = AppStorageV2.connect(
      WaitingResponseState,
      AI_STORAGE_KEYS.IS_WAITING_RESPONSE,
      () => new WaitingResponseState()
    )
    if (waitingState !== undefined) {
      waitingState.isWaiting = false
    }

    // 重置缓冲区
    typeStringBuffer.reset()

    aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}已重置所有状态`)
  }

  /**
   * 创建新会话
   */
  createNewConversation(modelType: AIModelType = AIModelType.NOT_SELECTED): string {
    // 先重置所有状态
    this.resetAllStates()

    const conversationId: string = generateConversationId()
    this.currentConversationId = conversationId
    this.hasSubstantialContent = false

    // 设置模型类型
    const modelState = AppStorageV2.connect(
      CurrentModelTypeState,
      AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
      () => new CurrentModelTypeState()
    )
    if (modelState !== undefined) {
      modelState.modelType = modelType
    }

    aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}创建新会话: ${conversationId}, 模型: ${modelType}`)
    return conversationId
  }

  /**
   * 发送消息
   */
  async sendMessage(userInput: string): Promise<boolean> {
    if (userInput.trim() === '') {
      aiLogger.warn(`${AI_LOG_TAG.CHAT_MANAGER}消息内容为空`)
      return false
    }

    // 获取当前模型类型
    const modelState = AppStorageV2.connect(
      CurrentModelTypeState,
      AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
      () => new CurrentModelTypeState()
    )
    if (modelState === undefined || modelState.modelType === AIModelType.NOT_SELECTED) {
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}未选择AI模型`)
      return false
    }

    // 获取消息列表
    const messageList = AppStorageV2.connect(
      MessageHistoryList,
      AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
      () => new MessageHistoryList()
    )
    if (messageList === undefined) {
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}消息列表未初始化`)
      return false
    }

    // 添加用户消息到历史
    const userMessage = new ViewMessageModel(MessageRole.User, userInput)
    messageList.addMessage(userMessage)

    // 标记有实质性内容
    this.hasSubstantialContent = true

    // 设置等待状态
    const waitingState = AppStorageV2.connect(
      WaitingResponseState,
      AI_STORAGE_KEYS.IS_WAITING_RESPONSE,
      () => new WaitingResponseState()
    )
    if (waitingState !== undefined) {
      waitingState.isWaiting = true
    }

    // 准备接收AI回复的消息对象
    const currentMsg = AppStorageV2.connect(
      ViewMessageModel,
      AI_STORAGE_KEYS.CURRENT_RECEIVING_MESSAGE,
      () => new ViewMessageModel()
    )
    if (currentMsg !== undefined) {
      currentMsg.content = ''
      currentMsg.hasEnd = false
      currentMsg.role = MessageRole.Assistant
      typeStringBuffer.setCurrentMessage(currentMsg)
    }

    aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}发送消息: ${userInput.substring(0, 50)}...`)

    // 调用 Coze API
    const success: boolean = await cozeAPI.sendMessage(
      this.currentConversationId,
      modelState.modelType,
      messageList,
      currentMsg!
    )

    if (success) {
      // 保存会话记录
      await this.saveCurrentConversation()
    }

    return success
  }

  /**
   * 查找会话记录
   */
  private findConversation(conversations: ConversationRecord[], id: string): ConversationRecord | null {
    for (let i = 0; i < conversations.length; i++) {
      if (conversations[i].id === id) {
        return conversations[i]
      }
    }
    return null
  }

  /**
   * 查找第一条用户消息
   */
  private findFirstUserMessage(messages: ViewMessageModel[]): ViewMessageModel | null {
    for (let i = 0; i < messages.length; i++) {
      if (messages[i].role === MessageRole.User) {
        return messages[i]
      }
    }
    return null
  }

  /**
   * 保存当前会话到数据库
   */
  private async saveCurrentConversation(): Promise<void> {
    if (this.kvStore === null || !this.hasSubstantialContent) {
      return
    }

    try {
      const messageList = AppStorageV2.connect(
        MessageHistoryList,
        AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
        () => new MessageHistoryList()
      )
      
      const modelState = AppStorageV2.connect(
        CurrentModelTypeState,
        AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
        () => new CurrentModelTypeState()
      )

      if (messageList === undefined || messageList.length === 0) {
        return
      }

      // 保存消息列表
      const messagesKey: string = `${AI_KV_DB_KEYS.CONVERSATION_PREFIX}${this.currentConversationId}`
      await this.kvStore.put(messagesKey, JSON.stringify(messageList.getMessages()))

      // 更新会话记录
      const conversationList = AppStorageV2.connect(
        ConversationHistoryList,
        AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
        () => new ConversationHistoryList()
      )

      if (conversationList !== undefined) {
        const existingConv = this.findConversation(conversationList.getConversations(), this.currentConversationId)
        
        if (existingConv !== null) {
          // 更新现有会话
          conversationList.updateConversation(this.currentConversationId, existingConv.title, messageList.length)
        } else {
          // 创建新会话记录
          const firstUserMsg = this.findFirstUserMessage(messageList.getMessages())
          let title: string = '新对话'
          if (firstUserMsg !== null) {
            title = firstUserMsg.content.substring(0, 20)
          }
          
          let modelTypeToUse: AIModelType = AIModelType.NOT_SELECTED
          if (modelState !== undefined) {
            modelTypeToUse = modelState.modelType
          }
          
          const newConv = new ConversationRecord(this.currentConversationId, modelTypeToUse)
          newConv.title = title
          newConv.messageCount = messageList.length
          conversationList.addConversation(newConv)
        }

        // 保存会话列表
        await this.saveConversationHistory()
      }

      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}会话已保存: ${this.currentConversationId}`)
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}保存会话失败: ${err.message}`)
    }
  }

  /**
   * 保存会话历史列表
   */
  private async saveConversationHistory(): Promise<void> {
    if (this.kvStore === null) {
      return
    }

    try {
      const conversationList = AppStorageV2.connect(
        ConversationHistoryList,
        AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
        () => new ConversationHistoryList()
      )

      if (conversationList !== undefined) {
        await this.kvStore.put(
          AI_KV_DB_KEYS.CONVERSATION_ID_LIST,
          JSON.stringify(conversationList.getConversations())
        )
      }
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}保存会话历史列表失败: ${err.message}`)
    }
  }

  /**
   * 加载会话历史列表
   */
  private async loadConversationHistory(): Promise<void> {
    if (this.kvStore === null) {
      return
    }

    try {
      const data: string = await this.kvStore.get(AI_KV_DB_KEYS.CONVERSATION_ID_LIST) as string
      const conversations: ConversationRecord[] = JSON.parse(data) as ConversationRecord[]

      const conversationList = AppStorageV2.connect(
        ConversationHistoryList,
        AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
        () => new ConversationHistoryList()
      )

      if (conversationList !== undefined) {
        conversationList.setConversations(conversations)
      }

      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}加载会话历史: ${conversations.length} 条`)
    } catch (error) {
      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}无历史会话记录`)
    }
  }

  /**
   * 加载指定会话的消息
   */
  async loadConversation(conversationId: string): Promise<boolean> {
    if (this.kvStore === null) {
      return false
    }

    // 先重置所有状态，取消当前请求
    this.resetAllStates()

    try {
      const messagesKey: string = `${AI_KV_DB_KEYS.CONVERSATION_PREFIX}${conversationId}`
      const data: string = await this.kvStore.get(messagesKey) as string
      const messages: ViewMessageModel[] = JSON.parse(data) as ViewMessageModel[]

      const messageList = AppStorageV2.connect(
        MessageHistoryList,
        AI_STORAGE_KEYS.CURRENT_MESSAGE_LIST,
        () => new MessageHistoryList()
      )

      if (messageList !== undefined) {
        for (let i = 0; i < messages.length; i++) {
          const msg = messages[i]
          const viewMsg = new ViewMessageModel(msg.role, msg.content)
          viewMsg.id = msg.id
          viewMsg.timestamp = msg.timestamp
          viewMsg.hasEnd = true
          messageList.addMessage(viewMsg)
        }
      }

      // 获取会话的模型类型
      const conversationList = AppStorageV2.connect(
        ConversationHistoryList,
        AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
        () => new ConversationHistoryList()
      )

      if (conversationList !== undefined) {
        const conv = this.findConversation(conversationList.getConversations(), conversationId)
        if (conv !== null) {
          const modelState = AppStorageV2.connect(
            CurrentModelTypeState,
            AI_STORAGE_KEYS.CURRENT_MODEL_TYPE,
            () => new CurrentModelTypeState()
          )
          if (modelState !== undefined) {
            modelState.modelType = conv.modelType
          }
        }
      }

      this.currentConversationId = conversationId
      this.hasSubstantialContent = true

      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}加载会话成功: ${conversationId}`)
      return true
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}加载会话失败: ${err.message}`)
      return false
    }
  }

  /**
   * 删除会话
   */
  async deleteConversation(conversationId: string): Promise<boolean> {
    if (this.kvStore === null) {
      return false
    }

    try {
      // 删除消息数据
      const messagesKey: string = `${AI_KV_DB_KEYS.CONVERSATION_PREFIX}${conversationId}`
      await this.kvStore.delete(messagesKey)

      // 从列表中移除
      const conversationList = AppStorageV2.connect(
        ConversationHistoryList,
        AI_STORAGE_KEYS.CONVERSATION_HISTORY_LIST,
        () => new ConversationHistoryList()
      )

      if (conversationList !== undefined) {
        conversationList.removeConversation(conversationId)
        await this.saveConversationHistory()
      }

      aiLogger.info(`${AI_LOG_TAG.CHAT_MANAGER}删除会话成功: ${conversationId}`)
      return true
    } catch (error) {
      const err = error as BusinessError
      aiLogger.error(`${AI_LOG_TAG.CHAT_MANAGER}删除会话失败: ${err.message}`)
      return false
    }
  }

  /**
   * 获取当前会话ID
   */
  getCurrentConversationId(): string {
    return this.currentConversationId
  }

  /**
   * 检查当前会话是否有实质性内容
   */
  hasContent(): boolean {
    return this.hasSubstantialContent
  }
}

export const chatManager: ChatManager = new ChatManager()
