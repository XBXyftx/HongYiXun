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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, HistoryItem } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { historyManager } from "feature"
import { AppStorageV2, promptAction } from "@kit.ArkUI"

@ComponentV2
export struct DateHistoryPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local historyList: HistoryItem[] = []
  @Local isLoading: boolean = false
  @Local dateStr: string = ''

  async aboutToAppear(): Promise<void> {
    // 从路由参数获取日期
    const pathInfo: Array<string> = this.navPathStuck.getParamByName(NAV_DESTS.DATE_HISTORY) as Array<string>
    if (pathInfo && pathInfo.length > 0) {
      this.dateStr = pathInfo[0]
      await this.loadHistory()
    }
  }

  async loadHistory(): Promise<void> {
    this.isLoading = true
    try {
      this.historyList = await historyManager.getHistoryByDate(this.dateStr)
    } catch (error) {
      console.error('加载历史记录失败:', JSON.stringify(error))
      promptAction.openToast({ message: '加载失败', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }

  formatDisplayDate(): string {
    if (!this.dateStr) return ''
    const parts = this.dateStr.split('-')
    if (parts.length === 3) {
      return `${parts[0]}年${parseInt(parts[1])}月${parseInt(parts[2])}日`
    }
    return this.dateStr
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    return `${hours}:${minutes}`
  }

  @Builder
  HistoryItemBuilder(item: HistoryItem) {
    Row() {
      Column() {
        Text(item.article.title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
          .fontWeight(600)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor($r('app.color.text_primary'))

        Row() {
          Text(item.article.source ?? '')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)

          Text('·')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 5, right: 5 })

          Text(this.formatTime(item.timestamp))
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
            .fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($rawfile('arrow_right.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fillColor($r('app.color.text_secondary'))
        .margin({ left: 10 })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.navPathStuck.pushPath({
        name: NAV_DESTS.ARTICLE,
        param: item.article
      })
    })
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Image($rawfile('empty_history.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .opacity(0.5)

      Text('当天没有阅读记录')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        Row() {
          Image($rawfile('back.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => {
              this.navPathStuck.pop()
            })

          Column() {
            Text(this.formatDisplayDate())
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
              .fontWeight(700)
              .fontColor($r('app.color.text_primary'))

            Text(`共 ${this.historyList.length} 篇`)
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
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

        // 历史记录列表
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.historyList.length === 0) {
          this.EmptyStateBuilder()
        } else {
          List({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
            ForEach(this.historyList, (item: HistoryItem) => {
              ListItem() {
                this.HistoryItemBuilder(item)
              }
              .padding(4)
            }, (item: HistoryItem) => item.article.id + item.timestamp)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({
            left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
            right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
          })
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideBackButton(true)
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}
