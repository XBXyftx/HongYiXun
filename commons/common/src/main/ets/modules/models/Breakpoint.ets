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

import { mediaquery } from '@kit.ArkUI'

/**
 * 断点类型枚举
 * 
 * 定义响应式布局的断点类型
 * 
 * @type BreakpointType
 * 
 * @remarks
 * - xs: 超小屏幕（如手机竖屏）
 * - sm: 小屏幕（如手机横屏）
 * - md: 中等屏幕（如平板）
 * - lg: 大屏幕（如PC）
 * - xl: 超大屏幕
 * - xxl: 超超大屏幕
 */
export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl'

/**
 * 断点接口
 * 
 * 定义响应式布局断点的数据结构
 * 
 * @interface Breakpoint
 * 
 * @remarks
 * 用于实现响应式布局，根据屏幕宽度自动调整界面
 * 
 * 断点规则：
 * - xs: 0-320vp（超小屏幕）
 * - sm: 320-600vp（小屏幕，手机竖屏）
 * - md: 600-840vp（中等屏幕，手机横屏/小平板）
 * - lg: 840-1024vp（大屏幕，平板）
 * - xl: 1024vp+（超大屏幕，桌面）
 * 
 * @example
 * ```typescript
 * const breakpoint: Breakpoint = {
 *   name: 'sm',
 *   size: 320,
 *   mediaQueryListener: mediaquery.matchMediaSync('(min-width: 320vp)')
 * }
 * ```
 * 
 * @see BreakPointSystem 断点系统管理类
 */
export interface Breakpoint {
  /** 
   * 断点名称
   * 
   * 对应 BreakpointType 类型
   */
  name: BreakpointType
  
  /** 
   * 断点触发的最小宽度
   * 
   * 单位：vp（虚拟像素）
   */
  size: number
  
  /** 
   * 媒体查询监听器实例（可选）
   * 
   * 用于监听屏幕宽度变化
   */
  mediaQueryListener?: mediaquery.MediaQueryListener
}
