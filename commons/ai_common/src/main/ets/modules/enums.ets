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

/**
 * AI模型类型枚举
 * 
 * 定义智能体的工作模式，通过不同的 workflow_id 调用不同的对话流
 */
export enum AIModelType {
  /** 未选择模式 - 初始状态，需要用户选择 */
  NOT_SELECTED = 'NOT_SELECTED',
  /** 快速回答模式 - 响应速度快，适合简单问题 */
  QUICK_ANSWER = 'QUICK_ANSWER',
  /** 深度思考模式 - 深度搜索分析，适合复杂问题 */
  DEEP_THINKING = 'DEEP_THINKING'
}

/**
 * AI模型配置 Map
 * 
 * 存储各模式对应的 workflow_id
 * TODO: 填入实际的 workflow_id
 */
export const AI_WORKFLOW_CONFIG: Map<AIModelType, string> = new Map<AIModelType, string>([
  [AIModelType.NOT_SELECTED, ''],
  [AIModelType.QUICK_ANSWER, ''], // TODO: 填入快速回答的 workflow_id
  [AIModelType.DEEP_THINKING, ''] // TODO: 填入深度思考的 workflow_id
])

/**
 * 消息角色枚举
 */
export enum MessageRole {
  /** 用户消息 */
  User = 'user',
  /** AI助手消息 */
  Assistant = 'assistant'
}

/**
 * 消息类型枚举
 */
export enum MessageType {
  /** 用户问题 */
  Question = 'question',
  /** AI回答 */
  Answer = 'answer',
  /** 函数调用 */
  FunctionCall = 'function_call',
  /** 工具响应 */
  ToolResponse = 'tool_response'
}

/**
 * AI AppStorageV2 键值枚举
 */
export enum AI_STORAGE_KEYS {
  /** 当前选择的AI模型类型 */
  CURRENT_MODEL_TYPE = 'ai_current_model_type',
  /** 当前会话ID */
  CURRENT_CONVERSATION_ID = 'ai_current_conversation_id',
  /** 当前正在接收的消息 */
  CURRENT_RECEIVING_MESSAGE = 'ai_current_receiving_message',
  /** 当前会话的消息历史 */
  CURRENT_MESSAGE_LIST = 'ai_current_message_list',
  /** 是否正在等待AI响应 */
  IS_WAITING_RESPONSE = 'ai_is_waiting_response',
  /** 会话历史记录列表 */
  CONVERSATION_HISTORY_LIST = 'ai_conversation_history_list'
}

/**
 * AI KV数据库键枚举
 */
export enum AI_KV_DB_KEYS {
  /** 会话历史记录前缀 - 实际键为 CONVERSATION_PREFIX + conversationId */
  CONVERSATION_PREFIX = 'ai_conversation_',
  /** 所有会话ID列表 */
  CONVERSATION_ID_LIST = 'ai_conversation_id_list'
}

/**
 * AI日志标签枚举
 */
export enum AI_LOG_TAG {
  /** Coze API */
  COZE_API = 'CozeAPI: ',
  /** 聊天管理器 */
  CHAT_MANAGER = 'ChatManager: ',
  /** 消息缓冲区 */
  MESSAGE_BUFFER = 'MessageBuffer: ',
  /** AI页面 */
  AI_PAGE = 'AIPage: '
}
