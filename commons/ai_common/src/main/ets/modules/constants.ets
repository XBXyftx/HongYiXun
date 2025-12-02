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
 * Coze API 配置类
 */
export class CozeApiConfig {
  /** API 基础地址 */
  static readonly BASE_URL: string = 'https://api.coze.cn'
  /** 对话流执行接口 */
  static readonly WORKFLOW_CHAT_URL: string = 'https://api.coze.cn/v1/workflows/chat'
  /** 请求超时时间（毫秒） */
  static readonly TIMEOUT_MS: number = 1200000
  /** 内容类型 */
  static readonly CONTENT_TYPE: string = 'application/json'
}

/**
 * 消息内容类型常量类
 */
export class ContentType {
  static readonly TEXT: string = 'text'
  static readonly IMAGE: string = 'image'
  static readonly FILE: string = 'file'
}

/**
 * 输入框配置类
 */
export class InputConfig {
  /** 最小输入长度 */
  static readonly MIN_LENGTH: number = 1
  /** 最大输入长度 */
  static readonly MAX_LENGTH: number = 2000
  /** 占位符文本 */
  static readonly PLACEHOLDER: string = '请输入您的问题...'
}

/**
 * 打字机效果配置类
 */
export class TypewriterConfig {
  /** 每个字符的显示间隔（毫秒） */
  static readonly CHAR_INTERVAL_MS: number = 6
  /** 开始延迟（毫秒） */
  static readonly START_DELAY_MS: number = 200
}

/**
 * AI KV 数据库 ID
 */
export const AI_KV_DB_ID: string = 'ai_kv_database'
