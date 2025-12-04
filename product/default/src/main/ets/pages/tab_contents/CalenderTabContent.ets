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
  @Local dailyStats: DailyReadingStats[] = []
  @Local heatmapCells: HeatmapCell[] = []
  @Local isLoading: boolean = false
  @Local totalReadCount: number = 0

  async aboutToAppear(): Promise<void> {
    await this.loadDailyStats()
  }

  @Monitor('historyUpdateTrigger.trigger')
  async onHistoryUpdate(): Promise<void> {
    await this.loadDailyStats()
  }

  @Monitor('userConfig.heatmapTimeRange')
  async onTimeRangeChange(): Promise<void> {
    await this.loadDailyStats()
  }

  @Monitor('userConfig.heatmapColorRange')
  onColorRangeChange(): void {
    this.generateHeatmapCells()
  }

  @Monitor('userConfig.heatmapColorScheme')
  onColorSchemeChange(): void {
    this.generateHeatmapCells()
  }

  async loadDailyStats(): Promise<void> {
    this.isLoading = true
    try {
      this.dailyStats = await historyManager.getDailyStatsInRange(this.userConfig.heatmapTimeRange)
      this.generateHeatmapCells()
      this.totalReadCount = this.dailyStats.reduce((sum, stat) => sum + stat.count, 0)
    } catch (error) {
      console.error('加载每日统计失败:', JSON.stringify(error))
    } finally {
      this.isLoading = false
    }
  }

  generateHeatmapCells(): void {
    this.heatmapCells = []
    const statsMap = new Map<string, number>()
    this.dailyStats.forEach(stat => {
      statsMap.set(stat.dateStr, stat.count)
    })

    const today = new Date()
    for (let i = this.userConfig.heatmapTimeRange - 1; i >= 0; i--) {
      const date = new Date(today)
      date.setDate(today.getDate() - i)
      const dateStr = this.formatDate(date)
      const count = statsMap.get(dateStr) || 0

      this.heatmapCells.push({
        dateStr: dateStr,
        count: count,
        color: this.getColorForCount(count),
        dayOfWeek: date.getDay(),
        dayOfMonth: date.getDate(),
        month: date.getMonth() + 1
      })
    }
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

    // 定义5个等级的颜色（从无到最亮）
    const colorSchemes: Record<string, string[]> = {
      [HeatmapColorScheme.BLUE]: ['#2d333b', '#0e4429', '#006d32', '#26a641', '#39d353'],
      [HeatmapColorScheme.GREEN]: ['#2d333b', '#0e4429', '#006d32', '#26a641', '#39d353'],
      [HeatmapColorScheme.RED]: ['#2d333b', '#5c2121', '#8b3d3d', '#d35f5f', '#ff8080'],
      [HeatmapColorScheme.GRAY]: ['#2d333b', '#404040', '#606060', '#909090', '#c0c0c0']
    }

    // 蓝色系使用GitHub风格的绿色，更容易区分
    if (scheme === HeatmapColorScheme.BLUE) {
      const blueColors = ['#2d333b', '#1e3a5f', '#2563eb', '#60a5fa', '#93c5fd']
      if (count === 0) return blueColors[0]
      if (ratio <= 0.25) return blueColors[1]
      if (ratio <= 0.5) return blueColors[2]
      if (ratio <= 0.75) return blueColors[3]
      return blueColors[4]
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
      this.navPathStuck.pushPath({
        name: NAV_DESTS.DATE_HISTORY,
        param: cell.dateStr
      })
    }
  }

  /**
   * 将热力格子按周分组（每列7天，从周日开始）
   */
  getWeekColumns(): HeatmapCell[][] {
    const weeks: HeatmapCell[][] = []
    
    if (this.heatmapCells.length === 0) return weeks

    // 获取第一天是周几
    const firstDayOfWeek = this.heatmapCells[0].dayOfWeek
    
    // 在第一周前面填充空白格子
    let currentWeek: HeatmapCell[] = []
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

    // 添加实际的格子
    for (const cell of this.heatmapCells) {
      currentWeek.push(cell)
      if (currentWeek.length === 7) {
        weeks.push(currentWeek)
        currentWeek = []
      }
    }

    // 处理最后一周不满7天的情况
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

            // 热力日历网格
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
                          }, (cell: HeatmapCell) => cell.dateStr || `empty_${cell.dayOfWeek}`)
                        }
                      }, (_: HeatmapCell[], idx: number) => `week_${idx}`)
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
            .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })

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
  }
}
