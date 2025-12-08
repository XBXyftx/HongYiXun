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
  APP_STORAGE_KEYS,
  UserConfigViewModel,
  HeatmapColorScheme,
  HeatmapTimeRange,
  HeatmapColorRange
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { userConfigManager } from "feature"

interface OptionItem {
  label: string
  value: number | string
}

@ComponentV2
export struct HeatmapSettingsPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!

  // 时间范围选项
  timeRangeOptions: OptionItem[] = [
    { label: '最近7天', value: HeatmapTimeRange.DAYS_7 },
    { label: '最近30天', value: HeatmapTimeRange.DAYS_30 },
    { label: '最近90天', value: HeatmapTimeRange.DAYS_90 },
    { label: '最近180天', value: HeatmapTimeRange.DAYS_180 },
    { label: '最近365天', value: HeatmapTimeRange.DAYS_365 }
  ]

  // 颜色范围选项
  colorRangeOptions: OptionItem[] = [
    { label: '0-10篇', value: HeatmapColorRange.RANGE_10 },
    { label: '0-50篇', value: HeatmapColorRange.RANGE_50 },
    { label: '0-100篇', value: HeatmapColorRange.RANGE_100 },
    { label: '0-500篇', value: HeatmapColorRange.RANGE_500 }
  ]

  // 颜色系选项
  colorSchemeOptions: OptionItem[] = [
    { label: '蓝色系', value: HeatmapColorScheme.BLUE },
    { label: '绿色系', value: HeatmapColorScheme.GREEN },
    { label: '红色系', value: HeatmapColorScheme.RED },
    { label: '灰色系', value: HeatmapColorScheme.GRAY }
  ]

  getTimeRangeLabel(): string {
    const option = this.timeRangeOptions.find(o => o.value === this.userConfig.heatmapTimeRange)
    return option ? option.label : '最近30天'
  }

  getColorRangeLabel(): string {
    const option = this.colorRangeOptions.find(o => o.value === this.userConfig.heatmapColorRange)
    return option ? option.label : '0-500篇'
  }

  getColorSchemeLabel(): string {
    const option = this.colorSchemeOptions.find(o => o.value === this.userConfig.heatmapColorScheme)
    return option ? option.label : '蓝色系'
  }

  saveConfig(): void {
    userConfigManager.syncDataToPreference()
  }

  @Builder
  SettingItemBuilder(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      Text(value)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: 8 })

      Image($rawfile('arrow_right.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fillColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .onClick(onClick)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  SwitchItemBuilder(title: string, subtitle: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
          .fontColor($r('app.color.text_primary'))

        Text(subtitle)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor($r('app.color.brand'))
        .onChange((value: boolean) => {
          onChange(value)
        })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  TimeRangeSelector() {
    Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12 }) {
      ForEach(this.timeRangeOptions, (option: OptionItem) => {
        Row() {
          Text(option.label)
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          if (this.userConfig.heatmapTimeRange === option.value) {
            Image($rawfile('check_icon.svg'))
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .fillColor($r('app.color.brand'))
          }
        }
        .width('100%')
        .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
        .backgroundColor(this.userConfig.heatmapTimeRange === option.value ? $r('app.color.brand_light') : Color.Transparent)
        .borderRadius(8)
        .onClick(() => {
          this.userConfig.heatmapTimeRange = option.value as number
          this.saveConfig()
          promptAction.openToast({ message: '已更新时间范围', duration: 1500 })
        })
      })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
  }

  @Builder
  ColorRangeSelector() {
    Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12 }) {
      ForEach(this.colorRangeOptions, (option: OptionItem) => {
        Row() {
          Text(option.label)
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          if (this.userConfig.heatmapColorRange === option.value) {
            Image($rawfile('check_icon.svg'))
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .fillColor($r('app.color.brand'))
          }
        }
        .width('100%')
        .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
        .backgroundColor(this.userConfig.heatmapColorRange === option.value ? $r('app.color.brand_light') : Color.Transparent)
        .borderRadius(8)
        .onClick(() => {
          this.userConfig.heatmapColorRange = option.value as number
          this.saveConfig()
          promptAction.openToast({ message: '已更新颜色范围', duration: 1500 })
        })
      })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
  }

  @Builder
  ColorSchemeSelector() {
    Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12 }) {
      ForEach(this.colorSchemeOptions, (option: OptionItem) => {
        Row() {
          Text(option.label)
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          if (this.userConfig.heatmapColorScheme === option.value) {
            Image($rawfile('check_icon.svg'))
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .fillColor($r('app.color.brand'))
          }
        }
        .width('100%')
        .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
        .backgroundColor(this.userConfig.heatmapColorScheme === option.value ? $r('app.color.brand_light') : Color.Transparent)
        .borderRadius(8)
        .onClick(() => {
          this.userConfig.heatmapColorScheme = option.value as string
          this.saveConfig()
          promptAction.openToast({ message: '已更新颜色系', duration: 1500 })
        })
      })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        Row() {
          Image($rawfile('back.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => {
              this.navPathStuck.pop()
            })

          Text('热力日历设置')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 26)
            .fontWeight(600)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 12 })

          Blank()
        }
        .width('100%')
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          top: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          bottom: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16
        })

        // 设置列表
        Scroll() {
          Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
            // 时间范围设置
            Text('显示范围')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 4, bottom: 4 })

            this.TimeRangeSelector()

            // 颜色范围设置
            Text('颜色范围')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 4, bottom: 4, top: 8 })

            this.ColorRangeSelector()

            // 颜色系设置
            Text('颜色系')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 4, bottom: 4, top: 8 })

            this.ColorSchemeSelector()

            // 点击跳转设置
            Text('交互设置')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 4, bottom: 4, top: 8 })

            this.SwitchItemBuilder(
              '点击跳转历史',
              '点击日期方块跳转至当天阅读记录',
              this.userConfig.heatmapClickToHistory,
              (value: boolean) => {
                this.userConfig.heatmapClickToHistory = value
                this.saveConfig()
              }
            )
          }
          .padding({
            left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            bottom: this.deviceType === DEVICE_TYPES.PHONE ? 24 : 32
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}
