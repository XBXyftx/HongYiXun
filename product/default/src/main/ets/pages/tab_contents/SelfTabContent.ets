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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, HistoryUpdateTrigger } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { historyManager } from "feature"
import { AppStorageV2 } from "@kit.ArkUI"

@ComponentV2
export struct SelfTabContent {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local historyUpdateTrigger: HistoryUpdateTrigger = 
    AppStorageV2.connect(HistoryUpdateTrigger, APP_STORAGE_KEYS.HISTORY_UPDATE_TRIGGER, () => new HistoryUpdateTrigger())!
  @Local historyCount: number = 0

  async aboutToAppear(): Promise<void> {
    await this.updateHistoryCount()
  }

  /**
   * 监听历史记录更新触发器
   */
  @Monitor('historyUpdateTrigger.trigger')
  async onHistoryUpdate(): Promise<void> {
    await this.updateHistoryCount()
  }

  /**
   * 更新历史记录数量
   */
  async updateHistoryCount(): Promise<void> {
    const historyList = await historyManager.getHistoryList()
    this.historyCount = historyList.length
  }

  @Builder
  MenuCardBuilder(icon: Resource, title: string, subtitle: string, badge?: number, onClick?: () => void) {
    Row() {
      // 图标
      Image(icon)
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
        .fillColor($r('app.color.brand'))
        .margin({ right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20 })

      // 文字信息
      Column() {
        Text(title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
        
        Text(subtitle)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 徽章和箭头
      Row() {
        if (badge !== undefined && badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.brand'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .margin({ right: 8 })
        }
        
        Image($rawfile('arrow_right.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.text_secondary'))
      }
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
      radius: 8,
      color: 'rgba(0, 0, 0, 0.05)',
      offsetY: 2
    })
    .transition(TransitionEffect.scale({ x: 0.95, y: 0.95 }).animation({ duration: 200, curve: Curve.EaseInOut }))
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('我的')
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

      // 功能菜单列表
      Scroll() {
        Column({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
          // 浏览历史卡片
          this.MenuCardBuilder(
            $rawfile('history_icon.svg'),
            '浏览历史',
            '查看你浏览过的新闻',
            this.historyCount,
            () => {
              this.navPathStuck.pushPath({ name: NAV_DESTS.HISTORY })
            }
          )

          // 预留其他功能卡片位置
          // 可以在这里添加更多功能入口，如：
          // - 我的收藏
          // - 阅读统计
          // - 设置
          // - 关于
        }
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea()
  }
}