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

import { DEVICE_TYPES, APP_STORAGE_KEYS, UserConfigViewModel } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { userConfigManager } from "feature"

interface StyleOption {
  label: string
  value: number
  description: string
}

@ComponentV2
export struct NoteEditorStyleSettingsPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!

  // 样式选项
  styleOptions: StyleOption[] = [
    { label: '底部弹窗', value: 0, description: '从屏幕底部弹出' },
    { label: '居中弹窗', value: 1, description: '在屏幕中央显示' },
    { label: '跟手弹窗', value: 2, description: '跟随点击位置弹出' },
    { label: '侧边弹窗', value: 3, description: '从屏幕侧边滑出' },
    { label: '全屏弹窗', value: 4, description: '覆盖整个屏幕' }
  ]

  saveConfig(): void {
    userConfigManager.syncDataToPreference()
  }

  @Builder
  StyleOptionBuilder(option: StyleOption) {
    Row() {
      Column() {
        Text(option.label)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
          .fontColor($r('app.color.text_primary'))

        Text(option.description)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.userConfig.noteEditorSheetType === option.value) {
        Image($rawfile('check_icon.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.brand'))
      }
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
    .backgroundColor(this.userConfig.noteEditorSheetType === option.value ?
      $r('app.color.brand_light') : $r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .onClick(() => {
      this.userConfig.noteEditorSheetType = option.value
      this.saveConfig()
      promptAction.openToast({ message: `已切换为${option.label}`, duration: 1500 })
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

          Text('笔记编辑页样式')
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
            Text('选择笔记编辑器的弹出样式')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 4, bottom: 4 })

            ForEach(this.styleOptions, (option: StyleOption) => {
              this.StyleOptionBuilder(option)
            })

            // 提示信息
            Text('注意：不同屏幕宽度支持的样式可能不同')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 16, left: 4 })
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
