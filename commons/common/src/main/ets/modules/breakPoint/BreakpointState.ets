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
import { BreakpointType } from "./BreakPointSystem"

export enum BREAK_POINT_ENUM {
  xs = 'xs',
  sm = 'sm',
  md = 'md',
  lg = 'lg',
  xl = 'xl',
  xxl = 'xxl'
}

/**
 * 断点状态管理类（观察者模式）
 * 根据当前断点类型切换对应配置值
 */
@ObservedV2
export class BreakpointState{
  /** 当前生效的状态值*/
  @Trace public value: BREAK_POINT_ENUM  = BREAK_POINT_ENUM.xs

  /**
   * 工厂方法创建实例
   * 创建一个断点监听器
   * @param options 当前组件不同断点状态数据
   */
  static of(): BreakpointState {
    return new BreakpointState()
  }

  /**
   * 获取当前的断点状态
   * @returns 断点状态简写字符串
   */
  public getCurrentBreakPointType() {
    return this.value?.toString()
  }

  /** 根据断点类型更新状态值 */
  public update(type: BreakpointType): void {
    // 通过条件判断选择对应配置[1](@ref)
    if (type === 'xs') {
      this.value = BREAK_POINT_ENUM.xs
    } else if (type === 'sm') {
      this.value = BREAK_POINT_ENUM.sm
    } else if (type === 'md') {
      this.value = BREAK_POINT_ENUM.md
    } else if (type === 'lg') {
      this.value = BREAK_POINT_ENUM.lg
    } else if (type === 'xl') {
      this.value = BREAK_POINT_ENUM.xl
    } else if (type === 'xxl') {
      this.value = BREAK_POINT_ENUM.xxl
    } else {
      this.value = BREAK_POINT_ENUM.xs // 未知类型重置状态
    }
  }
}