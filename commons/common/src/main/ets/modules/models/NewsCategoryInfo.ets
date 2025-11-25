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

import { NEWS_CATEGORY, KV_DB_KEYS } from '../enums'

/**
 * 新闻栏目信息接口
 * 
 * 定义新闻分类栏目的完整信息，用于新闻列表的分栏切换功能
 * 
 * @interface NewsCategoryInfo
 * 
 * @remarks
 * 栏目配置特点：
 * - 统一管理：所有栏目信息集中配置
 * - 状态标识：区分已开发和待开发功能
 * - API 映射：关联后端接口参数
 * - 数据库映射：关联本地存储键
 * 
 * 使用场景：
 * - 新闻列表头部的栏目切换
 * - 数据加载时的 API 调用
 * - 本地缓存的数据存储
 * 
 * @example
 * ```typescript
 * const categoryInfo: NewsCategoryInfo = {
 *   id: NEWS_CATEGORY.OPENHARMONY_OFFICIAL,
 *   displayName: "开源鸿蒙官方动态",
 *   apiCategory: "openharmony_official",
 *   dbKey: KV_DB_KEYS.NEWS_OPENHARMONY_OFFICIAL,
 *   isDeveloped: true
 * }
 * ```
 * 
 * @see NEWS_CATEGORY 新闻栏目类别枚举
 * @see KV_DB_KEYS 数据库键枚举
 * @see NewsList 新闻列表组件
 */
export interface NewsCategoryInfo {
  /** 
   * 栏目 ID
   * 
   * 使用 NEWS_CATEGORY 枚举值，作为栏目的唯一标识
   */
  id: NEWS_CATEGORY
  
  /** 
   * 栏目显示名称
   * 
   * 在用户界面中显示的栏目名称
   * 
   * @example "开源鸿蒙官方动态"
   */
  displayName: string
  
  /** 
   * 后端 API 的 category 参数值
   * 
   * 调用后端接口时使用的分类参数
   * 
   * @remarks
   * - 已开发栏目：具体的 API 参数值
   * - 待开发栏目：空字符串
   * 
   * @example "openharmony_official"
   */
  apiCategory: string
  
  /** 
   * 数据库存储键
   * 
   * 使用 KV_DB_KEYS 枚举值，用于本地缓存数据
   */
  dbKey: KV_DB_KEYS
  
  /** 
   * 是否已开发
   * 
   * 标识该栏目功能是否已实现
   * 
   * @remarks
   * - true: 功能已实现，可以正常使用
   * - false: 功能待开发，点击时显示提示
   */
  isDeveloped: boolean
}
