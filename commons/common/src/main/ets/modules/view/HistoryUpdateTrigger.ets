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
 * 历史记录更新触发器
 * 
 * 用于通知历史记录页面刷新数据的全局触发器
 * 
 * @remarks
 * 工作原理：
 * 1. HistoryManager 在添加/删除历史记录后，递增 trigger 值
 * 2. SelfTabContent 监听 trigger 变化，自动重新加载数据
 * 3. 实现跨组件的数据同步
 */
@ObservedV2
export class HistoryUpdateTrigger {
  /**
   * 触发器计数器
   * 
   * 每次历史记录变化时递增该值
   * 组件通过 @Monitor 监听该值的变化来刷新数据
   */
  @Trace trigger: number = 0
}
