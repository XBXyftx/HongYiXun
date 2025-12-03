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
 * 快速刷新结果接口
 * 
 * 用于两阶段刷新的第一阶段返回结果
 */
export interface QuickRefreshResult {
  /** 是否成功 */
  success: boolean
  /** 成功加载的栏目数量 */
  loadedCount: number
}

/**
 * 完整刷新结果接口
 * 
 * 用于两阶段刷新的第二阶段返回结果
 */
export interface FullRefreshResult {
  /** 是否成功 */
  success: boolean
  /** 成功更新的栏目数量 */
  updatedCount: number
}

/**
 * 刷新进度信息接口
 * 
 * 用于完整刷新时的进度回调
 */
export interface RefreshProgress {
  /** 栏目名称 */
  category: string
  /** 当前进度 */
  current: number
  /** 总数 */
  total: number
}

/**
 * 栏目加载结果接口
 * 
 * 用于记录单个栏目的加载结果
 */
export interface CategoryLoadResult {
  /** 栏目名称 */
  category: string
  /** 是否成功 */
  success: boolean
  /** 加载的新闻条数 */
  count: number
}
