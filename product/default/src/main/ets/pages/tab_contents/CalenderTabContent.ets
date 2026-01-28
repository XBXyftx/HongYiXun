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

import {
  DEVICE_TYPES,
  NAV_DESTS,
  APP_STORAGE_KEYS,
  UserConfigViewModel,
  DailyReadingStats,
  HeatmapColorScheme,
  HistoryUpdateTrigger
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { historyManager } from "feature"
import { AppStorageV2 } from "@kit.ArkUI"

// 共享元素转场ID
const HEATMAP_SHARED_ID = 'heatmap_shared_element'

/**
 * 热力日历单元格数据
 */
interface HeatmapCell {
  dateStr: string
  count: number
  color: string
  dayOfWeek: number
  dayOfMonth: number
  month: number
}

/**
 * 月历日期单元格
 */
interface CalendarDayCell {
  day: number
  dateStr: string
  count: number
  color: string
  isCurrentMonth: boolean
  isToday: boolean
}

@ComponentV2
export struct CalenderTabContent {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!
  @Local historyUpdateTrigger: HistoryUpdateTrigger =
    AppStorageV2.connect(HistoryUpdateTrigger, APP_STORAGE_KEYS.HISTORY_UPDATE_TRIGGER, () => new HistoryUpdateTrigger())!
  @Local heatmapCells: HeatmapCell[] = []
  @Local isLoading: boolean = false
  @Local totalReadCount: number = 0
  // 全屏模态控制
  @Local isFullscreenShow: boolean = false
  @Local cardAlpha: number = 1
  // 月历相关
  @Local currentYear: number = new Date().getFullYear()
  @Local currentMonth: number = new Date().getMonth() + 1
  @Local calendarDays: CalendarDayCell[] = []
  // 优化：直接使用 Map 存储阅读数量，避免数组转换
  @Local statsMap: Map<string, number> = new Map()
  async aboutToAppear(): Promise<void> {
    await this.loadDailyStats()
    this.generateCalendarDays()
  }

  /**
   * 下拉刷新空内容Builder
   */
  @Builder
  refreshingBuilder() {
    Stack() {
    }.width('100%')
  }


  @Monitor('historyUpdateTrigger.trigger')
  async onHistoryUpdate(): Promise<void> {
    await this.loadDailyStats()
    this.generateHeatmapCells()
    this.generateCalendarDays()
  }

  @Monitor('userConfig.heatmapTimeRange')
  async onTimeRangeChange(): Promise<void> {
    await this.loadDailyStats()
  }

  @Monitor('userConfig.heatmapColorRange')
  onColorRangeChange(): void {
    // 颜色范围变化时，需要重新计算所有格子的颜色
    this.generateHeatmapCells()
    this.generateCalendarDays()
  }

  @Monitor('userConfig.heatmapColorScheme')
  onColorSchemeChange(): void {
    // 颜色系变化时，需要重新计算所有格子的颜色
    this.generateHeatmapCells()
    this.generateCalendarDays()
  }

  @Monitor('currentMonth')
  onMonthChange(): void {
    this.generateCalendarDays()
  }

  @Monitor('currentYear')
  onYearChange(): void {
    this.generateCalendarDays()
  }

  async loadDailyStats(): Promise<void> {
    this.isLoading = true
    try {
      // 优化：直接加载 Map，避免数组转换
      const timeRange = this.userConfig.heatmapTimeRange
      const newStatsMap = await historyManager.getDailyCountMapInRange(365)
      
      // 强制触发 Map 更新（重新赋值以触发响应式）
      this.statsMap = newStatsMap
      
      this.generateHeatmapCells()
      
      // 计算总阅读数
      this.totalReadCount = 0
      const today = new Date()
      this.statsMap.forEach((count, dateStr) => {
        const date = new Date(dateStr)
        const diffDays = Math.floor((today.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))
        if (diffDays < timeRange) {
          this.totalReadCount += count
        }
      })
    } catch (error) {
      console.error('加载每日统计失败:', JSON.stringify(error))
    } finally {
      this.isLoading = false
    }
  }

  generateHeatmapCells(): void {
    const today = new Date()
    const timeRange = this.userConfig.heatmapTimeRange
    const newCells: HeatmapCell[] = []

    // 从最早的日期开始计算（timeRange - 1 天前）
    for (let i = timeRange - 1; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(today.getDate() - i)
      const dateStr = this.formatDate(date)
      const count = this.statsMap.get(dateStr) || 0

      newCells.push({
        dateStr: dateStr,
        count: count,
        color: this.getColorForCount(count), // 每次都重新计算颜色
        dayOfWeek: date.getDay(),
        dayOfMonth: date.getDate(),
        month: date.getMonth() + 1
      })
    }
    
    // 强制触发数组更新（重新赋值以触发响应式）
    this.heatmapCells = newCells
  }

  generateCalendarDays(): void {
    const days: CalendarDayCell[] = []
    const today = new Date()
    const todayStr = this.formatDate(today)

    const firstDay = new Date(this.currentYear, this.currentMonth - 1, 1)
    const lastDay = new Date(this.currentYear, this.currentMonth, 0)
    const firstDayOfWeek = firstDay.getDay()
    const daysInMonth = lastDay.getDate()

    const prevMonthLastDay = new Date(this.currentYear, this.currentMonth - 1, 0)
    const prevMonthDays = prevMonthLastDay.getDate()

    // 填充上个月的日期
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const day = prevMonthDays - i
      const date = new Date(this.currentYear, this.currentMonth - 2, day)
      const dateStr = this.formatDate(date)
      const count = this.statsMap.get(dateStr) || 0
      days.push({
        day: day,
        dateStr: dateStr,
        count: count,
        color: this.getColorForCount(count),
        isCurrentMonth: false,
        isToday: dateStr === todayStr
      })
    }

    // 填充当月日期
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(this.currentYear, this.currentMonth - 1, day)
      const dateStr = this.formatDate(date)
      const count = this.statsMap.get(dateStr) || 0
      days.push({
        day: day,
        dateStr: dateStr,
        count: count,
        color: this.getColorForCount(count),
        isCurrentMonth: true,
        isToday: dateStr === todayStr
      })
    }

    // 填充下个月的日期
    const remainingDays = 42 - days.length
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(this.currentYear, this.currentMonth, day)
      const dateStr = this.formatDate(date)
      const count = this.statsMap.get(dateStr) || 0
      days.push({
        day: day,
        dateStr: dateStr,
        count: count,
        color: this.getColorForCount(count),
        isCurrentMonth: false,
        isToday: dateStr === todayStr
      })
    }

    this.calendarDays = days
  }

  formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  getColorForCount(count: number): string {
    const maxRange = this.userConfig.heatmapColorRange
    const ratio = Math.min(count / maxRange, 1)
    const scheme = this.userConfig.heatmapColorScheme

    if (scheme === HeatmapColorScheme.BLUE) {
      const blueColors = ['#2d333b', '#1e3a5f', '#2563eb', '#60a5fa', '#93c5fd']
      if (count === 0) return blueColors[0]
      if (ratio <= 0.25) return blueColors[1]
      if (ratio <= 0.5) return blueColors[2]
      if (ratio <= 0.75) return blueColors[3]
      return blueColors[4]
    }

    const colorSchemes: Record<string, string[]> = {
      [HeatmapColorScheme.GREEN]: ['#2d333b', '#0e4429', '#006d32', '#26a641', '#39d353'],
      [HeatmapColorScheme.RED]: ['#2d333b', '#5c2121', '#8b3d3d', '#d35f5f', '#ff8080'],
      [HeatmapColorScheme.GRAY]: ['#2d333b', '#404040', '#606060', '#909090', '#c0c0c0']
    }

    const colors = colorSchemes[scheme] || colorSchemes[HeatmapColorScheme.GREEN]
    if (count === 0) return colors[0]
    if (ratio <= 0.25) return colors[1]
    if (ratio <= 0.5) return colors[2]
    if (ratio <= 0.75) return colors[3]
    return colors[4]
  }

  getLegendColors(): string[] {
    const scheme = this.userConfig.heatmapColorScheme
    if (scheme === HeatmapColorScheme.BLUE) {
      return ['#2d333b', '#1e3a5f', '#2563eb', '#60a5fa', '#93c5fd']
    }
    const colorSchemes: Record<string, string[]> = {
      [HeatmapColorScheme.GREEN]: ['#2d333b', '#0e4429', '#006d32', '#26a641', '#39d353'],
      [HeatmapColorScheme.RED]: ['#2d333b', '#5c2121', '#8b3d3d', '#d35f5f', '#ff8080'],
      [HeatmapColorScheme.GRAY]: ['#2d333b', '#404040', '#606060', '#909090', '#c0c0c0']
    }
    return colorSchemes[scheme] || colorSchemes[HeatmapColorScheme.GREEN]
  }

  onCellClick(cell: HeatmapCell): void {
    if (this.userConfig.heatmapClickToHistory && cell.count > 0) {
      // 如果全屏模态打开，先收起再导航
      if (this.isFullscreenShow) {
        this.onFullscreenBack()
      }
      this.navPathStuck.replacePath({
        name: NAV_DESTS.DATE_HISTORY,
        param: cell.dateStr
      })
    }
  }

  onCalendarCellClick(dateStr: string, count: number): void {
    if (this.userConfig.heatmapClickToHistory && count > 0) {
      // 如果全屏模态打开，先收起再导航
      if (this.isFullscreenShow) {
        this.onFullscreenBack()
      }
      this.navPathStuck.replacePath({
        name: NAV_DESTS.DATE_HISTORY,
        param: dateStr
      })
    }
  }

  getWeekColumns(): HeatmapCell[][] {
    const weeks: HeatmapCell[][] = []
    if (this.heatmapCells.length === 0) return weeks

    // 获取第一天是星期几（0=周日, 1=周一, ..., 6=周六）
    const firstDayOfWeek = this.heatmapCells[0].dayOfWeek
    let currentWeek: HeatmapCell[] = []

    // 在第一周前面填充空白格子，对齐星期
    for (let i = 0; i < firstDayOfWeek; i++) {
      currentWeek.push({
        dateStr: '',
        count: 0,
        color: 'transparent',
        dayOfWeek: i,
        dayOfMonth: 0,
        month: 0
      })
    }

    // 遍历所有热力格子
    for (const cell of this.heatmapCells) {
      currentWeek.push(cell)
      // 当一周满7天时，保存这一周并开始新的一周
      if (currentWeek.length === 7) {
        weeks.push(currentWeek)
        currentWeek = []
      }
    }

    // 处理最后一周：如果不足7天，在后面填充空白格子
    if (currentWeek.length > 0) {
      while (currentWeek.length < 7) {
        currentWeek.push({
          dateStr: '',
          count: 0,
          color: 'transparent',
          dayOfWeek: currentWeek.length,
          dayOfMonth: 0,
          month: 0
        })
      }
      weeks.push(currentWeek)
    }
    
    return weeks
  }

  prevMonth(): void {
    if (this.currentMonth === 1) {
      this.currentMonth = 12
      this.currentYear--
    } else {
      this.currentMonth--
    }
  }

  nextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentMonth = 1
      this.currentYear++
    } else {
      this.currentMonth++
    }
  }

  /**
   * 点击展开全屏
   */
  private onExpandClick(): void {
    this.getUIContext()?.animateTo({
      duration: 350,
      curve: Curve.Friction
    }, () => {
      this.isFullscreenShow = true
      this.cardAlpha = 0
    })
  }

  /**
   * 从全屏返回
   */
  private onFullscreenBack(): void {
    this.getUIContext()?.animateTo({
      duration: 350,
      curve: Curve.Friction
    }, () => {
      this.isFullscreenShow = false
      this.cardAlpha = 1
    })
  }


  @Builder
  HeatmapCellBuilder(cell: HeatmapCell, index: number) {
    Column() {
    }
    .width(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
    .height(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
    .backgroundColor(cell.color)
    .borderRadius(2)
    .margin(1)
    .onClick(() => this.onCellClick(cell))
  }

  @Builder
  LegendBuilder() {
    Row() {
      Text('少')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 10 : 12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: 4 })

      ForEach(this.getLegendColors(), (color: string) => {
        Column()
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
          .backgroundColor(color)
          .borderRadius(2)
          .margin({ right: 2 })
      })

      Text('多')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 10 : 12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ left: 4 })
    }
    .justifyContent(FlexAlign.Center)
    .margin({ top: 16 })
  }

  @Builder
  CalendarDayCellBuilder(cell: CalendarDayCell) {
    Column() {
      Text(`${cell.day}`)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
        .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(cell.isCurrentMonth ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
    }
    .width('100%')
    .aspectRatio(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(cell.count > 0 ? cell.color : Color.Transparent)
    .borderRadius(this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12)
    .border({
      width: cell.isToday ? 2 : 0,
      color: $r('app.color.brand')
    })
    .onClick(() => this.onCalendarCellClick(cell.dateStr, cell.count))
  }

  /**
   * 全屏模态页面内容Builder
   */
  @Builder
  fullscreenContentBuilder() {
    GridRow({ columns: { sm: 4, md: 8, lg: 12 } }) {
      GridCol({ span: { sm: 4, md: 6, lg: 6 }, offset: { sm: 0, md: 1, lg: 3 } }) {
        Column() {
          // 标题栏
          Row() {
            Text('阅读热力日历')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 26)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)

            // 关闭按钮
            SymbolGlyph($r('sys.symbol.arrow_down_right_and_arrow_up_left'))
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32)
              .fontColor([$r('app.color.text_primary')])
              .onClick(() => this.onFullscreenBack())
          }
          .width('100%')
          .padding({
            left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
            bottom: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16
          })
          .margin({ top: 48 }) // 固定顶部边距，避开状态栏

          // 使用Refresh组件实现下拉返回手势
          Refresh({ refreshing: false, builder: this.refreshingBuilder, offset: 4 }) {
            Scroll() {
              Column() {
                // 统计信息卡片
                Column() {
                  Text(`最近 ${this.userConfig.heatmapTimeRange} 天共阅读`)
                    .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
                    .fontColor($r('app.color.text_secondary'))

                  Row() {
                    Text(`${this.totalReadCount}`)
                      .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 36 : 48)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.brand'))

                    Text(' 篇文章')
                      .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
                      .fontColor($r('app.color.text_primary'))
                      .margin({ bottom: 4 })
                  }
                  .alignItems(VerticalAlign.Bottom)
                }
                .width('100%')
                .padding(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28)
                .backgroundColor($r('app.color.news_list_item_bg'))
                .borderRadius(16)
                .alignItems(HorizontalAlign.Start)
                .margin({
                  left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
                  right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
                })

                // 热力日历网格 - 共享元素
                Column() {
                  // 热力格子
                  Scroll() {
                    Row() {
                      // 星期标签列
                      Column() {
                        ForEach(['', '一', '', '三', '', '五', ''], (day: string) => {
                          Text(day)
                            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 9 : 11)
                            .fontColor($r('app.color.text_secondary'))
                            .height(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
                            .width(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
                            .textAlign(TextAlign.End)
                            .margin({ right: 4 })
                        })
                      }

                      // 热力格子网格
                      Scroll() {
                        Row() {
                          ForEach(this.getWeekColumns(), (weekCells: HeatmapCell[], weekIndex: number) => {
                            Column() {
                              ForEach(weekCells, (cell: HeatmapCell, dayIndex: number) => {
                                this.HeatmapCellBuilder(cell, weekIndex * 7 + dayIndex)
                              }, (cell: HeatmapCell, dayIdx: number) => `fs_${this.userConfig.heatmapTimeRange}_${this.userConfig.heatmapColorRange}_${this.userConfig.heatmapColorScheme}_${this.historyUpdateTrigger.trigger}_${cell.dateStr || 'empty'}_${dayIdx}_${cell.count}_${cell.color}`)
                            }
                          }, (weekCells: HeatmapCell[], idx: number) => `fs_week_${this.userConfig.heatmapTimeRange}_${this.userConfig.heatmapColorRange}_${this.userConfig.heatmapColorScheme}_${this.historyUpdateTrigger.trigger}_${idx}_${weekCells.length}`)
                        }
                      }
                      .scrollable(ScrollDirection.Horizontal)
                      .scrollBar(BarState.Off)
                      .layoutWeight(1)
                    }
                  }
                  .scrollable(ScrollDirection.Horizontal)
                  .scrollBar(BarState.Off)
                  .width('100%')

                  // 图例
                  this.LegendBuilder()

                  // 范围说明
                  Text(`颜色范围: 0 - ${this.userConfig.heatmapColorRange} 篇`)
                    .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 10 : 12)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 8 })
                }
                .width('100%')
                .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24)
                .backgroundColor($r('app.color.news_list_item_bg'))
                .borderRadius(16)
                .margin({
                  top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
                  left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
                  right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
                })
                // 共享元素转场 - 与卡片的id对应
                .geometryTransition(HEATMAP_SHARED_ID)
                .transition(TransitionEffect.OPACITY.animation({ duration: 350, curve: Curve.Friction }))

                // 月历视图
                Column() {
                  // 月份导航
                  Row() {
                    Image($r('sys.media.ohos_ic_public_arrow_left'))
                      .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32)
                      .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32)
                      .fillColor($r('app.color.text_primary'))
                      .onClick(() => this.prevMonth())

                    Text(`${this.currentYear}年${this.currentMonth}月`)
                      .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                      .textAlign(TextAlign.Center)

                    Image($r('sys.media.ohos_ic_public_arrow_right'))
                      .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32)
                      .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32)
                      .fillColor($r('app.color.text_primary'))
                      .onClick(() => this.nextMonth())
                  }
                  .width('100%')
                  .padding({ bottom: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24 })

                  // 星期标题
                  Row() {
                    ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
                      Text(day)
                        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
                        .fontColor($r('app.color.text_secondary'))
                        .width('14.28%')
                        .textAlign(TextAlign.Center)
                    })
                  }
                  .width('100%')
                  .padding({ bottom: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12 })

                  // 日期网格
                  Grid() {
                    ForEach(this.calendarDays, (cell: CalendarDayCell, index: number) => {
                      GridItem() {
                        this.CalendarDayCellBuilder(cell)
                      }
                    }, (cell: CalendarDayCell, idx: number) => `cal_${this.historyUpdateTrigger.trigger}_${cell.dateStr}_${cell.count}_${cell.color}`)
                  }
                  .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
                  .rowsGap(this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8)
                  .columnsGap(this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8)
                  .width('100%')
                }
                .width('100%')
                .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24)
                .backgroundColor($r('app.color.news_list_item_bg'))
                .borderRadius(16)
                .margin({
                  top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
                  left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
                  right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
                })

                // 提示文字
                if (this.userConfig.heatmapClickToHistory) {
                  Text('点击有阅读记录的日期可查看当天阅读的文章')
                    .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({
                      top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16,
                      left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
                      right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
                      bottom: this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32
                    })
                }
              }
            }
            .scrollable(ScrollDirection.Vertical)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .width('100%')
            .height('100%')
          }
          .onRefreshing(() => {
            // 下拉刷新时触发返回
            this.onFullscreenBack()
          })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    // 只扩展底部安全区域，顶部保持避开状态栏
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .transition(TransitionEffect.asymmetric(
      TransitionEffect.opacity(1),
      TransitionEffect.OPACITY
    ))
  }


  build() {
    Column() {
      // 标题栏
      Row() {
        Text('阅读热力日历')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 28 : 34)
          .fontWeight(700)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({
        left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
        top: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28,
        bottom: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 统计信息卡片
            Column() {
              Text(`最近 ${this.userConfig.heatmapTimeRange} 天共阅读`)
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
                .fontColor($r('app.color.text_secondary'))

              Row() {
                Text(`${this.totalReadCount}`)
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 36 : 48)
                  .fontWeight(700)
                  .fontColor($r('app.color.brand'))

                Text(' 篇文章')
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ bottom: 4 })
              }
              .alignItems(VerticalAlign.Bottom)
            }
            .width('100%')
            .padding(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28)
            .backgroundColor($r('app.color.news_list_item_bg'))
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)

            // 热力日历网格 - 添加共享元素转场
            Stack({ alignContent: Alignment.TopEnd }) {
              Column() {
                // 热力格子 - 使用Grid布局，每行7天
                Scroll() {
                  Row() {
                    // 星期标签列
                    Column() {
                      ForEach(['', '一', '', '三', '', '五', ''], (day: string, index: number) => {
                        Text(day)
                          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 9 : 11)
                          .fontColor($r('app.color.text_secondary'))
                          .height(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
                          .width(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
                          .textAlign(TextAlign.End)
                          .margin({ right: 4 })
                      })
                    }

                    // 热力格子网格
                    Scroll() {
                      Row() {
                        ForEach(this.getWeekColumns(), (weekCells: HeatmapCell[], weekIndex: number) => {
                          Column() {
                            ForEach(weekCells, (cell: HeatmapCell, dayIndex: number) => {
                              this.HeatmapCellBuilder(cell, weekIndex * 7 + dayIndex)
                            }, (cell: HeatmapCell, dayIdx: number) => `main_${this.userConfig.heatmapTimeRange}_${this.userConfig.heatmapColorRange}_${this.userConfig.heatmapColorScheme}_${this.historyUpdateTrigger.trigger}_${cell.dateStr || 'empty'}_${dayIdx}_${cell.count}_${cell.color}`)
                          }
                        }, (weekCells: HeatmapCell[], idx: number) => `main_week_${this.userConfig.heatmapTimeRange}_${this.userConfig.heatmapColorRange}_${this.userConfig.heatmapColorScheme}_${this.historyUpdateTrigger.trigger}_${idx}_${weekCells.length}`)
                      }
                    }
                    .scrollable(ScrollDirection.Horizontal)
                    .scrollBar(BarState.Off)
                    .layoutWeight(1)
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')

                // 图例
                this.LegendBuilder()

                // 范围说明
                Text(`颜色范围: 0 - ${this.userConfig.heatmapColorRange} 篇`)
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 10 : 12)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24)
              .padding({ top: this.deviceType === DEVICE_TYPES.PHONE ? 40 : 48 })

              // 全屏按钮 - 右上角
              Row() {
                SymbolGlyph($r('sys.symbol.arrow_up_left_and_arrow_down_right'))
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
                  .fontColor([$r('app.color.text_secondary')])
              }
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
              .borderRadius(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
              .backgroundColor($r('app.color.card_bg'))
              .justifyContent(FlexAlign.Center)
              .margin({
                top: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12,
                right: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12
              })
              .onClick(() => this.onExpandClick())
            }
            .width('100%')
            .backgroundColor($r('app.color.news_list_item_bg'))
            .borderRadius(16)
            .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })
            .clip(true)
            // 共享元素转场 - follow: true 表示跟随目标组件
            .geometryTransition(HEATMAP_SHARED_ID, { follow: true })
            .transition(TransitionEffect.OPACITY.animation({ duration: 350, curve: Curve.Friction }))

            // 提示文字
            if (this.userConfig.heatmapClickToHistory) {
              Text('点击有阅读记录的日期可查看当天阅读的文章')
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })
            }
          }
          .padding({
            left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            bottom: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
    .opacity(this.cardAlpha)
    // 绑定全屏模态页面
    .bindContentCover(
      this.isFullscreenShow,
      this.fullscreenContentBuilder(),
      {
        modalTransition: ModalTransition.NONE,
        onWillDisappear: () => {
          this.isFullscreenShow = false
          this.cardAlpha = 1
        }
      }
    )
  }
}
