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
 * 新闻相关的数据模型已迁移到 models 目录
 * 
 * @see commons/common/src/main/ets/modules/models/NewsArticle.ets
 * 
 * 导出的类型：
 * - CONTENT_TYPE_ENUM: 内容类型枚举
 * - NewsContentBlock: 新闻内容块接口
 * - NewsArticle: 新闻文章类
 * - NewsResponse: 新闻响应接口
 */

// 从 models 重新导出，保持向后兼容
export { CONTENT_TYPE_ENUM, NewsContentBlock, NewsArticle, NewsResponse } from '../models/NewsArticle'
