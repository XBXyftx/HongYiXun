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

import { DEVICE_TYPES, logger, LOG_TAG, NAV_DESTS, APP_STORAGE_KEYS, HistoryUpdateTrigger } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { historyManager, HistoryItem } from "feature"
import { AppStorageV2, promptAction } from "@kit.ArkUI"

@ComponentV2
export struct HistoryPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local historyList: HistoryItem[] = []
  @Local isLoading: boolean = false
  @Local showClearDialog: boolean = false
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local historyUpdateTrigger: HistoryUpdateTrigger = 
    AppStorageV2.connect(HistoryUpdateTrigger, APP_STORAGE_KEYS.HISTORY_UPDATE_TRIGGER, () => new HistoryUpdateTrigger())!

  async aboutToAppear(): Promise<void> {
    await this.loadHistory()
  }

  /**
   * 监听历史记录更新触发器
   */
  @Monitor('historyUpdateTrigger.trigger')
  async onHistoryUpdate(): Promise<void> {
    logger.info(`${LOG_TAG.MAIN_PAGE}检测到历史记录更新，重新加载数据`)
    await this.loadHistory()
  }

  /**
   * 加载历史记录
   */
  async loadHistory(): Promise<void> {
    this.isLoading = true
    try {
      this.historyList = await historyManager.getHistoryList()
      logger.info(`${LOG_TAG.MAIN_PAGE}加载历史记录成功: ${this.historyList.length} 条`)
    } catch (error) {
      logger.error(`${LOG_TAG.MAIN_PAGE}加载历史记录失败: ${JSON.stringify(error)}`)
      promptAction.openToast({ message: '加载历史记录失败', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 删除单条历史记录
   */
  async deleteHistoryItem(articleId: string): Promise<void> {
    try {
      const success = await historyManager.deleteHistory(articleId)
      if (success) {
        promptAction.openToast({ message: '已删除', duration: 1500 })
      }
    } catch (error) {
      logger.error(`${LOG_TAG.MAIN_PAGE}删除历史记录失败: ${JSON.stringify(error)}`)
      promptAction.openToast({ message: '删除失败', duration: 2000 })
    }
  }

  /**
   * 清空所有历史记录
   */
  async clearAllHistory(): Promise<void> {
    try {
      const success = await historyManager.clearAllHistory()
      if (success) {
        promptAction.openToast({ message: '已清空历史记录', duration: 2000 })
      }
    } catch (error) {
      logger.error(`${LOG_TAG.MAIN_PAGE}清空历史记录失败: ${JSON.stringify(error)}`)
      promptAction.openToast({ message: '清空失败', duration: 2000 })
    }
    this.showClearDialog = false
  }

  /**
   * 格式化时间显示
   */
  formatTime(timestamp: number): string {
    const now = new Date().getTime()
    const diff = now - timestamp
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    if (hours < 24) return `${hours}小时前`
    if (days < 7) return `${days}天前`
    
    const date = new Date(timestamp)
    return `${date.getMonth() + 1}月${date.getDate()}日`
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
          Text(item.article.source)
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

      Image($rawfile('delete.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .fillColor($r('app.color.text_secondary'))
        .margin({ left: 10 })
        .onClick(() => {
          this.deleteHistoryItem(item.article.id)
        })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
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
      
      Text('暂无浏览历史')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 20 })
      
      Text('浏览过的新闻会显示在这里')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
        .fontColor($r('app.color.text_secondary'))
        .opacity(0.6)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ClearDialogBuilder() {
    Column() {
      Column() {
        Text('清空历史记录')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 16 })
        
        Text('确定要清空所有浏览历史吗？')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 24 })
        
        Row() {
          Button('取消')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor($r('app.color.button_secondary_bg'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .onClick(() => {
              this.showClearDialog = false
            })
          
          Button('确定')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.clearAllHistory()
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
          
          Text('浏览历史')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
            .fontWeight(700)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 12 })
          
          Blank()
          
          if (this.historyList.length > 0) {
            Button('清空')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .backgroundColor($r('app.color.button_secondary_bg'))
              .fontColor($r('app.color.text_primary'))
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
              .onClick(() => {
                this.showClearDialog = true
              })
          }
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
              .transition(TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut }))
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
      .bindContentCover(this.showClearDialog, this.ClearDialogBuilder(), {
        modalTransition: ModalTransition.DEFAULT
      })
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}