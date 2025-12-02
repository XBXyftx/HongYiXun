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

import { MessageRole, MessageType, AIModelType } from './enums'

/**
 * Coze API 请求体接口
 */
export interface ICozeRequestBody {
  /** 待执行的对话流 ID */
  workflow_id: string
  /** 对话中用户问题和历史消息 */
  additional_messages: CozeMessageItem[]
  /** 对话流输入参数 */
  parameters: Record<string, string>
  /** 会话 ID */
  conversation_id?: string
  /** 智能体 ID */
  bot_id?: string
  /** 应用 ID */
  app_id?: string
}

/**
 * Coze 历史消息项
 */
export class CozeMessageItem {
  /** 消息发送者角色 */
  role: MessageRole
  /** 消息类型 */
  type?: MessageType
  /** 消息内容 */
  content?: string
  /** 消息内容类型 */
  content_type?: string

  constructor(role: MessageRole) {
    this.role = role
  }

  /**
   * 克隆消息对象
   */
  clone(): CozeMessageItem {
    const newItem = new CozeMessageItem(this.role)
    if (this.type !== undefined) {
      newItem.type = this.type
    }
    if (this.content !== undefined) {
      newItem.content = this.content
    }
    if (this.content_type !== undefined) {
      newItem.content_type = this.content_type
    }
    return newItem
  }
}

/**
 * 流式响应中的消息增量数据
 */
export interface ICozeStreamDeltaData {
  id: string
  conversation_id: string
  role: string
  type: string
  content: string
  content_type: string
  chat_id: string
  section_id: string
}

/**
 * 生成唯一ID
 */
function generateUniqueId(): string {
  const timestamp = Date.now()
  const randomPart = Math.floor(Math.random() * 1000000).toString()
  return `${timestamp}_${randomPart}`
}

/**
 * 视图层消息模型 - 用于UI渲染
 */
@ObservedV2
export class ViewMessageModel {
  /** 消息唯一ID */
  @Trace id: string = ''
  /** 消息角色: user/assistant */
  @Trace role: MessageRole = MessageRole.User
  /** 消息内容 */
  @Trace content: string = ''
  /** 是否已完成接收 */
  @Trace hasEnd: boolean = true
  /** 消息时间戳 */
  @Trace timestamp: number = 0

  constructor(role: MessageRole = MessageRole.User, content: string = '') {
    this.id = generateUniqueId()
    this.role = role
    this.content = content
    this.timestamp = Date.now()
  }
}

/**
 * 消息历史列表模型
 */
@ObservedV2
export class MessageHistoryList {
  @Trace private messages: ViewMessageModel[] = []

  /** 获取消息列表 */
  getMessages(): ViewMessageModel[] {
    return this.messages
  }

  /** 添加消息 */
  addMessage(message: ViewMessageModel): void {
    this.messages.push(message)
  }

  /** 获取用于发送给API的消息格式 */
  getCozeMessages(): CozeMessageItem[] {
    const result: CozeMessageItem[] = []
    for (let i = 0; i < this.messages.length; i++) {
      const msg = this.messages[i]
      const item = new CozeMessageItem(msg.role)
      item.content = msg.content
      item.content_type = 'text'
      item.type = msg.role === MessageRole.User ? MessageType.Question : MessageType.Answer
      result.push(item)
    }
    return result
  }

  /** 清空消息 */
  clear(): void {
    this.messages = []
  }

  /** 获取消息数量 */
  get length(): number {
    return this.messages.length
  }
}

/**
 * 会话记录模型 - 用于持久化存储
 */
@ObservedV2
export class ConversationRecord {
  /** 会话唯一ID */
  @Trace id: string = ''
  /** 会话标题（取第一条用户消息的前20个字符） */
  @Trace title: string = ''
  /** 使用的AI模型类型 */
  @Trace modelType: AIModelType = AIModelType.NOT_SELECTED
  /** 创建时间 */
  @Trace createTime: number = 0
  /** 最后更新时间 */
  @Trace updateTime: number = 0
  /** 消息数量 */
  @Trace messageCount: number = 0

  constructor(id: string = '', modelType: AIModelType = AIModelType.NOT_SELECTED) {
    if (id === '') {
      this.id = `conv_${generateUniqueId()}`
    } else {
      this.id = id
    }
    this.modelType = modelType
    this.createTime = Date.now()
    this.updateTime = Date.now()
  }
}

/**
 * 会话历史列表模型
 */
@ObservedV2
export class ConversationHistoryList {
  @Trace private conversations: ConversationRecord[] = []

  /** 获取会话列表 */
  getConversations(): ConversationRecord[] {
    return this.conversations
  }

  /** 添加会话 */
  addConversation(conversation: ConversationRecord): void {
    this.conversations.unshift(conversation) // 新会话放在最前面
  }

  /** 更新会话 */
  updateConversation(id: string, title: string, messageCount: number): void {
    for (let i = 0; i < this.conversations.length; i++) {
      if (this.conversations[i].id === id) {
        this.conversations[i].title = title
        this.conversations[i].messageCount = messageCount
        this.conversations[i].updateTime = Date.now()
        break
      }
    }
  }

  /** 删除会话 */
  removeConversation(id: string): void {
    for (let i = 0; i < this.conversations.length; i++) {
      if (this.conversations[i].id === id) {
        this.conversations.splice(i, 1)
        break
      }
    }
  }

  /** 设置会话列表 */
  setConversations(conversations: ConversationRecord[]): void {
    this.conversations = conversations
  }

  /** 获取会话数量 */
  get length(): number {
    return this.conversations.length
  }
}

/**
 * 当前AI模型类型状态
 */
@ObservedV2
export class CurrentModelTypeState {
  @Trace modelType: AIModelType = AIModelType.NOT_SELECTED
}

/**
 * 等待响应状态
 */
@ObservedV2
export class WaitingResponseState {
  @Trace isWaiting: boolean = false
}

/**
 * 模型选项卡参数接口
 */
export interface IModelOptionParams {
  title: string
  description: string
  icon: Resource
  modelType: AIModelType
  isSelected: boolean
}

/**
 * 模型选项卡参数类
 */
export class ModelOptionParams implements IModelOptionParams {
  title: string = ''
  description: string = ''
  icon: Resource
  modelType: AIModelType = AIModelType.NOT_SELECTED
  isSelected: boolean = false

  constructor(
    title: string,
    description: string,
    icon: Resource,
    modelType: AIModelType,
    isSelected: boolean
  ) {
    this.title = title
    this.description = description
    this.icon = icon
    this.modelType = modelType
    this.isSelected = isSelected
  }
}