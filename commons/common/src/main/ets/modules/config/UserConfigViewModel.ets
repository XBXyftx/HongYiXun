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
 * 用户配置视图模型
 * 
 * 用于管理用户的个性化配置，支持响应式更新 UI
 * 
 * @remarks
 * 设计模式：
 * - MVVM 模式中的 ViewModel 层
 * - 使用 @ObservedV2 装饰器实现响应式
 * - 属性变化时自动更新关联的 UI 组件
 * 
 * 状态管理：
 * - 存储在 AppStorageV2 中，全局共享
 * - 键名：APP_STORAGE_KEYS.USER_CONFIG
 * - 生命周期：应用运行期间持续存在
 * 
 * 数据持久化：
 * - 运行时状态：AppStorageV2（内存）
 * - 持久化存储：PreferenceDB（磁盘）
 * - 同步管理：UserConfigManager
 * 
 * 数据流转：
 * ```
 * 用户操作 → UI 组件 → UserConfigViewModel (AppStorageV2)
 *                                    ↓
 *                              UserConfigManager
 *                                    ↓
 *                              PreferenceDB (持久化)
 * ```
 * 
 * 响应式机制：
 * - @Trace 装饰器：标记可追踪的属性
 * - 属性变化时，自动通知所有观察者
 * - UI 组件自动重新渲染
 * 
 * 使用场景：
 * - 文章阅读：根据字体大小设置显示文章
 * - 主题切换：根据颜色模式切换应用外观
 * - 设置页面：展示和修改用户配置
 * 
 * @example
 * ```typescript
 * // 1. 从 AppStorageV2 获取实例
 * const userConfig = AppStorageV2.connect(
 *   UserConfigViewModel,
 *   APP_STORAGE_KEYS.USER_CONFIG,
 *   () => new UserConfigViewModel()
 * )
 * 
 * // 2. 读取配置
 * console.log(`当前字体大小: ${userConfig.fontSize}`)
 * console.log(`当前颜色模式: ${userConfig.colorModel}`)
 * 
 * // 3. 修改配置（自动触发 UI 更新）
 * userConfig.fontSize = 18
 * userConfig.colorModel = 1
 * 
 * // 4. 持久化到数据库
 * userConfigManager.syncDataToPreference()
 * ```
 * 
 * @see UserConfigManager 用户配置管理器，负责数据同步
 * @see PreferenceEnum 偏好设置枚举，定义存储键名
 * @see APP_STORAGE_KEYS AppStorageV2 键值枚举
 */
import { HeatmapColorScheme, HeatmapTimeRange, HeatmapColorRange } from '../models/DailyReadingStats'

@ObservedV2
export class UserConfigViewModel {
  /**
   * 深浅色模式配置
   * 
   * 控制应用的整体颜色主题
   * 
   * @remarks
   * 取值范围：
   * - 0: 浅色模式（Light Mode）
   *   - 背景：白色或浅色
   *   - 文字：深色
   *   - 适合：白天使用，明亮环境
   * 
   * - 1: 深色模式（Dark Mode）
   *   - 背景：黑色或深色
   *   - 文字：浅色
   *   - 适合：夜间使用，暗光环境
   *   - 优势：减少眼睛疲劳，省电（OLED 屏幕）
   * 
   * - 2: 跟随系统（Follow System）
   *   - 自动跟随系统主题设置
   *   - 系统切换时应用自动切换
   *   - 推荐：提供最佳用户体验
   * 
   * 默认值：2（跟随系统）
   * 
   * 响应式：
   * - 使用 @Trace 装饰器
   * - 值变化时自动更新所有使用此配置的 UI
   * - ColorModManager 负责实际的主题切换
   * 
   * 持久化：
   * - 存储键：PreferenceEnum.COLOR_MODE
   * - 通过 PreferenceDB 保存到本地
   * - 应用重启后自动恢复
   * 
   * @type 0 | 1 | 2
   * @default 2
   * 
   * @example
   * ```typescript
   * // 设置为深色模式
   * userConfig.colorModel = 1
   * 
   * // 设置为跟随系统
   * userConfig.colorModel = 2
   * 
   * // 在组件中使用
   * @ComponentV2
   * struct SettingsPage {
   *   @Local userConfig = AppStorageV2.connect(...)
   *   
   *   build() {
   *     Text(`当前模式: ${userConfig.colorModel === 0 ? '浅色' : 
   *                      userConfig.colorModel === 1 ? '深色' : '跟随系统'}`)
   *   }
   * }
   * ```
   * 
   * @see ColorModManager 颜色模式管理器
   * @see ColorModChoseButton 颜色模式选择组件
   */
  @Trace colorModel: 0 | 1 | 2 = 2
  
  /**
   * 文章字体大小配置
   * 
   * 控制文章详情页中正文的字体大小
   * 
   * @remarks
   * 取值范围：
   * - 最小值：12（较小，适合视力好的用户）
   * - 推荐值：16（标准大小，适合大多数用户）
   * - 最大值：24（较大，适合视力较弱或老年用户）
   * 
   * 单位：fp（Font Pixel，字体像素）
   * - 与 sp 类似，会随系统字体缩放
   * - 确保在不同设备上保持一致的视觉效果
   * 
   * 默认值：16
   * 
   * 响应式：
   * - 使用 @Trace 装饰器
   * - 值变化时，文章页面的字体立即更新
   * - 无需刷新页面或重新加载
   * 
   * 持久化：
   * - 存储键：PreferenceEnum.FONT_SIZE
   * - 通过 PreferenceDB 保存到本地
   * - 应用重启后自动恢复用户设置
   * 
   * 影响范围：
   * - 文章详情页：正文内容
   * - 不影响：标题、按钮、列表等其他 UI 元素
   * 
   * 用户体验：
   * - 提供滑动条或步进器调整
   * - 实时预览效果
   * - 记住用户偏好
   * 
   * @type number
   * @default 16
   * 
   * @example
   * ```typescript
   * // 设置字体大小为 18
   * userConfig.fontSize = 18
   * 
   * // 增大字体
   * userConfig.fontSize = Math.min(userConfig.fontSize + 2, 24)
   * 
   * // 减小字体
   * userConfig.fontSize = Math.max(userConfig.fontSize - 2, 12)
   * 
   * // 在文章页面中使用
   * @ComponentV2
   * struct ArticlePage {
   *   @Local userConfig = AppStorageV2.connect(...)
   *   
   *   build() {
   *     Text(articleContent)
   *       .fontSize(userConfig.fontSize)  // 响应式字体大小
   *   }
   * }
   * ```
   * 
   * @see FontSizeAdjustButton 字体大小调整组件
   * @see ArticlePage 文章详情页
   */
  @Trace fontSize: number = 16

  // ==================== 热力日历配置 ====================

  /**
   * 热力日历显示的时间范围（天数）
   * @default 30
   */
  @Trace heatmapTimeRange: number = HeatmapTimeRange.DAYS_30

  /**
   * 热力日历颜色条的最大值范围
   * @default 500
   */
  @Trace heatmapColorRange: number = HeatmapColorRange.RANGE_500

  /**
   * 点击热力日历方块是否跳转至对应日期的历史记录
   * @default true
   */
  @Trace heatmapClickToHistory: boolean = true

  /**
   * 热力日历颜色系
   * @default 'blue'
   */
  @Trace heatmapColorScheme: string = HeatmapColorScheme.BLUE
}

/**
 * 窗口宽度包装类
 * 
 * 用于在 AppStorageV2 中存储和追踪窗口宽度变化
 * 
 * @remarks
 * 设计目的：
 * - AppStorageV2 需要存储对象类型
 * - 将基本类型 number 包装成类
 * - 支持响应式更新
 * 
 * 使用场景：
 * - 响应式布局：根据窗口宽度调整 UI
 * - 断点系统：配合 BreakpointSystem 使用
 * - 自适应设计：不同尺寸显示不同布局
 * 
 * 窗口宽度的应用：
 * - 小屏（<600px）：单列布局
 * - 中屏（600-840px）：两列布局
 * - 大屏（>840px）：三列或分栏布局
 * 
 * 更新时机：
 * - 应用启动：EntryAbility.onCreate()
 * - 窗口变化：屏幕旋转、分屏操作
 * - 设备切换：折叠屏展开/折叠
 * 
 * 单位说明：
 * - 存储的是像素值（px）
 * - 使用前需通过 getUIContext().px2vp() 转换为 vp
 * 
 * @example
 * ```typescript
 * // 1. 在 EntryAbility 中初始化
 * onCreate() {
 *   window.getLastWindow(this.context).then((win) => {
 *     const width = win.getWindowProperties().windowRect.width
 *     AppStorageV2.connect(
 *       WinWidth,
 *       APP_STORAGE_KEYS.WINDOW_WIDTH,
 *       () => new WinWidth(width)
 *     )
 *   })
 * }
 * 
 * // 2. 在页面中使用
 * @ComponentV2
 * struct StartPage {
 *   aboutToAppear() {
 *     const winWidth = AppStorageV2.connect(
 *       WinWidth,
 *       APP_STORAGE_KEYS.WINDOW_WIDTH
 *     )?.value ?? 350
 *     
 *     const widthVp = this.getUIContext().px2vp(winWidth)
 *     console.log(`窗口宽度: ${widthVp}vp`)
 *   }
 * }
 * 
 * // 3. 响应式布局示例
 * build() {
 *   const width = this.winWidth
 *   Column() {
 *     if (width < 600) {
 *       // 单列布局
 *     } else if (width < 840) {
 *       // 两列布局
 *     } else {
 *       // 三列布局
 *     }
 *   }
 * }
 * ```
 * 
 * @see EntryAbility 应用入口，初始化窗口宽度
 * @see BreakpointSystem 断点系统，基于宽度的响应式设计
 * @see APP_STORAGE_KEYS.WINDOW_WIDTH 存储键
 */
@ObservedV2
export class WinWidth {
  /**
   * 窗口宽度值
   * 
   * @remarks
   * - 单位：px（像素）
   * - 类型：number
   * - 响应式：使用 @Trace 装饰器
   * - 变化时机：窗口大小改变时更新
   * 
   * 注意事项：
   * - 直接使用是像素值，需要转换为 vp
   * - 不同设备的像素密度不同
   * - 建议通过 px2vp() 转换后使用
   * 
   * @type number
   */
  @Trace value: number

  /**
   * 构造函数
   * 
   * @param value - 窗口宽度（单位：px）
   * 
   * @remarks
   * 通常通过 window API 获取实际宽度值
   * 
   * @example
   * ```typescript
   * const width = window.getLastWindow().getWindowProperties().windowRect.width
   * const winWidth = new WinWidth(width)
   * ```
   */
  constructor(value: number) {
    this.value = value
  }
}
