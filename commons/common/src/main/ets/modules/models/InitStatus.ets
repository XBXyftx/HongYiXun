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
 * 应用初始化状态接口
 * 
 * 用于跟踪应用启动时各个模块的初始化状态
 * 
 * @interface InitStatus
 * 
 * @remarks
 * 在应用启动时，需要初始化多个模块（如数据库、用户配置、管理器等）
 * 该接口用于记录各模块的初始化状态，确保所有模块就绪后再显示主界面
 * 
 * @example
 * ```typescript
 * const initStatus: InitStatus = {
 *   databases: true,
 *   userConfig: true,
 *   managers: true,
 *   appStorageV2: true,
 *   markdown: true
 * }
 * ```
 */
export interface InitStatus {
  /** 
   * 数据库模块初始化状态
   * 
   * true 表示 KV 数据库和 Preference 数据库已成功初始化
   */
  databases: boolean
  
  /** 
   * 用户配置初始化状态
   * 
   * true 表示用户配置（字体大小、颜色模式等）已加载完成
   */
  userConfig: boolean
  
  /** 
   * 业务管理器初始化状态
   * 
   * true 表示新闻管理器、历史记录管理器等已初始化
   */
  managers: boolean
  
  /** 
   * AppStorageV2 初始化状态
   * 
   * true 表示全局状态管理已就绪
   */
  appStorageV2: boolean
  
  /** 
   * Markdown 配置初始化状态
   * 
   * true 表示 Markdown 渲染器已配置完成
   */
  markdown: boolean
}
