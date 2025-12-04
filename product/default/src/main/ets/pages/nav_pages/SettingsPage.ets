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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, UserConfigViewModel } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { historyManager } from "feature"

@ComponentV2
export struct SettingsPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel = AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!
  @Local showClearDialog: boolean = false

  /**
   * 获取颜色模式显示文本
   */
  getColorModeText(): string {
    switch (this.userConfig.colorModel) {
      case 0:
        return '浅色模式'
      case 1:
        return '深色模式'
      case 2:
        return '跟随系统'
      default:
        return '跟随系统'
    }
  }

  /**
   * 清理所有数据
   */
  async clearAllData(): Promise<void> {
    try {
      const success = await historyManager.clearAllData()
      if (success) {
        promptAction.openToast({ message: '已清空所有数据', duration: 2000 })
      } else {
        promptAction.openToast({ message: '清理失败', duration: 2000 })
      }
    } catch (error) {
      promptAction.openToast({ message: '清理失败', duration: 2000 })
    }
    this.showClearDialog = false
  }

  @Builder
  SettingItemBuilder(icon: Resource, title: string, value: string, onClick?: () => void) {
    Row() {
      // 图标
      Image(icon)
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
        .fillColor($r('app.color.brand'))
        .margin({ right: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })

      // 标题
      Text(title)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      // 当前值
      Text(value)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: 8 })

      // 箭头
      Image($rawfile('arrow_right.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fillColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .onClick(() => {
      if (onClick) {
        onClick()
      }
    })
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
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

          Text('设置')
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
            // 外观设置分组
            Text('外观')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({
                left: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8,
                bottom: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8
              })

            // 字体大小设置
            this.SettingItemBuilder(
              $rawfile('font_icon.svg'),
              '文章字体大小',
              `${this.userConfig.fontSize}`,
              () => {
                this.navPathStuck.replacePath({ name: NAV_DESTS.FONT_SIZE_SETTINGS })
              }
            )

            // 颜色模式设置
            this.SettingItemBuilder(
              $rawfile('theme_icon.svg'),
              '深浅色模式',
              this.getColorModeText(),
              () => {
                this.navPathStuck.replacePath({ name: NAV_DESTS.COLOR_MODE_SETTINGS })
              }
            )

            // 热力日历设置分组
            Text('热力日历')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({
                left: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8,
                top: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12,
                bottom: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8
              })

            // 热力日历设置
            this.SettingItemBuilder(
              $rawfile('calendar_icon.svg'),
              '热力日历设置',
              '',
              () => {
                this.navPathStuck.replacePath({ name: NAV_DESTS.HEATMAP_SETTINGS })
              }
            )

            // 数据管理分组
            Text('数据管理')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({
                left: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8,
                top: this.deviceType === DEVICE_TYPES.PHONE ? 8 : 12,
                bottom: this.deviceType === DEVICE_TYPES.PHONE ? 4 : 8
              })

            // 清理数据
            this.SettingItemBuilder(
              $rawfile('delete.svg'),
              '清理所有数据',
              '',
              () => {
                this.showClearDialog = true
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
      .bindContentCover(this.showClearDialog, this.ClearDialogBuilder(), {
        modalTransition: ModalTransition.DEFAULT
      })
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }

  @Builder
  ClearDialogBuilder() {
    Column() {
      Column() {
        Text('清理所有数据')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 16 })

        Text('确定要清空所有浏览历史和阅读统计数据吗？此操作不可恢复。')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 24 })
          .textAlign(TextAlign.Center)

        Row() {
          Button('取消')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor($r('app.color.button_secondary_bg'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .onClick(() => {
              this.showClearDialog = false
            })

          Button('确定清理')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor('#FF4444')
            .fontColor(Color.White)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.clearAllData()
            })
        }
        .width('100%')
      }
      .width(this.deviceType === DEVICE_TYPES.PHONE ? '80%' : '60%')
      .padding(24)
      .backgroundColor($r('app.color.dialog_bg'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.dialog_mask'))
  }
}
