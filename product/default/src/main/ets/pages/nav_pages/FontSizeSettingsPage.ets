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
import { userConfigManager } from "feature"

@ComponentV2
export struct FontSizeSettingsPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel = AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!
  @Local tempFontSize: number = 16

  aboutToAppear(): void {
    this.tempFontSize = this.userConfig.fontSize
  }

  /**
   * 应用字体大小更改
   */
  applyFontSize(): void {
    this.userConfig.fontSize = this.tempFontSize
    userConfigManager.syncDataToPreference()
    logger.info(`${LOG_TAG.USER_CONFIG_MANAGER}字体大小已更新为: ${this.tempFontSize}`)
    
    try {
      promptAction.openToast({
        message: `字体大小已设置为 ${this.tempFontSize}`,
        duration: 1500
      })
    } catch (error) {
      promptAction.openToast({
        message: `字体大小已设置为 ${this.tempFontSize}`,
        duration: 1500
      })
    }
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

          Text('文章字体大小')
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

        // 设置内容
        Column() {
          // 当前字体大小显示
          Column() {
            Text(`当前大小: ${this.tempFontSize}`)
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 16 })

            Text('示例文字 Example Text')
              .fontSize(this.tempFontSize)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 24 })
          }
          .width('100%')
          .padding(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28)
          .backgroundColor($r('app.color.news_list_item_bg'))
          .borderRadius(12)

          // 滑块调整
          Column() {
            Row() {
              Text('小')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              
              Slider({
                value: this.tempFontSize,
                min: 12,
                max: 24,
                step: 1
              })
                .layoutWeight(1)
                .margin({ left: 15, right: 15 })
                .trackColor($r('app.color.font_adjust_slider_track'))
                .selectedColor($r('app.color.font_adjust_slider_selected'))
                .blockColor($r('app.color.font_adjust_slider_selected'))
                .onChange((value: number) => {
                  this.tempFontSize = Math.round(value)
                  this.applyFontSize()
                })
              
              Text('大')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
          }
          .width('100%')
          .padding(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28)
          .backgroundColor($r('app.color.news_list_item_bg'))
          .borderRadius(12)
          .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })

          // 说明文字
          Text('调整文章详情页的字体大小，范围：12-24')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 })
        }
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}
