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

import { DEVICE_TYPES, APP_STORAGE_KEYS, UserConfigViewModel, logger, LOG_TAG } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { colorModManager } from "feature"

@ComponentV2
export struct ColorModeSettingsPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel = AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!

  /**
   * 设置颜色模式
   */
  setColorMode(mode: 0 | 1 | 2): void {
    this.userConfig.colorModel = mode
    
    switch (mode) {
      case 0:
        colorModManager.setLightMod()
        logger.info(`${LOG_TAG.COLOR_MOD_MANAGER}切换为浅色模式`)
        break
      case 1:
        colorModManager.setDarkMod()
        logger.info(`${LOG_TAG.COLOR_MOD_MANAGER}切换为深色模式`)
        break
      case 2:
        colorModManager.setDefaultColorMode()
        logger.info(`${LOG_TAG.COLOR_MOD_MANAGER}切换为跟随系统模式`)
        break
    }

    try {
      promptAction.openToast({
        message: mode === 0 ? '已切换为浅色模式' : mode === 1 ? '已切换为深色模式' : '已设置为跟随系统',
        duration: 1500
      })
    } catch (error) {
      promptAction.openToast({
        message: mode === 0 ? '已切换为浅色模式' : mode === 1 ? '已切换为深色模式' : '已设置为跟随系统',
        duration: 1500
      })
    }
  }

  @Builder
  ColorModeOptionBuilder(icon: Resource, title: string, description: string, mode: 0 | 1 | 2) {
    Row() {
      // 图标
      Image(icon)
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
        .fillColor(this.userConfig.colorModel === mode ? $r('app.color.brand') : $r('app.color.text_secondary'))
        .margin({ right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20 })

      // 文字信息
      Column() {
        Text(title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
          .fontWeight(this.userConfig.colorModel === mode ? 600 : 400)
          .fontColor($r('app.color.text_primary'))
        
        Text(description)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选中标记
      if (this.userConfig.colorModel === mode) {
        Image($rawfile('check_icon.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.brand'))
      }
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .border({
      width: 2,
      color: this.userConfig.colorModel === mode ? $r('app.color.brand') : Color.Transparent
    })
    .onClick(() => {
      this.setColorMode(mode)
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

          Text('深浅色模式')
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

        // 设置选项
        Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
          // 浅色模式
          this.ColorModeOptionBuilder(
            $rawfile('light_mode_icon.svg'),
            '浅色模式',
            '适合白天使用',
            0
          )

          // 深色模式
          this.ColorModeOptionBuilder(
            $rawfile('dark_mode_icon.svg'),
            '深色模式',
            '适合夜间使用，减少眼睛疲劳',
            1
          )

          // 跟随系统
          this.ColorModeOptionBuilder(
            $rawfile('auto_mode_icon.svg'),
            '跟随系统',
            '自动跟随系统主题设置',
            2
          )
        }
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}
