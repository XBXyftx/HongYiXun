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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, LikeUpdateTrigger, logger, LOG_TAG, LikeItem } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { likeManager } from "feature"

@ComponentV2
export struct LikesPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local likeUpdateTrigger: LikeUpdateTrigger =
    AppStorageV2.connect(LikeUpdateTrigger, APP_STORAGE_KEYS.LIKE_UPDATE_TRIGGER, () => new LikeUpdateTrigger())!
  @Local likeList: LikeItem[] = []
  @Local isLoading: boolean = true
  @Local showClearDialog: boolean = false

  async aboutToAppear(): Promise<void> {
    await this.loadLikes()
  }

  @Monitor('likeUpdateTrigger.trigger')
  async onLikeUpdate(): Promise<void> {
    logger.info(`${LOG_TAG.LIKE_MANAGER}检测到点赞更新，重新加载数据`)
    await this.loadLikes()
  }

  async loadLikes(): Promise<void> {
    this.isLoading = true
    try {
      this.likeList = await likeManager.getLikeList()
    } catch (error) {
      logger.error(`${LOG_TAG.LIKE_MANAGER}加载点赞列表失败: ${JSON.stringify(error)}`)
    } finally {
      this.isLoading = false
    }
  }

  async deleteLikeItem(articleId: string): Promise<void> {
    const success = await likeManager.removeLike(articleId)
    if (success) {
      promptAction.openToast({ message: '已取消点赞', duration: 1500 })
    }
  }

  async clearAllLikes(): Promise<void> {
    const success = await likeManager.clearAllLikes()
    if (success) {
      this.showClearDialog = false
      promptAction.openToast({ message: '已清空所有点赞', duration: 1500 })
    }
  }

  formatTime(timestamp: number): string {
    const now = Date.now()
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
  LikeItemBuilder(item: LikeItem) {
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

      Image($rawfile('delete.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .fillColor($r('app.color.text_secondary'))
        .margin({ left: 10 })
        .onClick(() => {
          this.deleteLikeItem(item.article.id)
        })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 20)
    .backgroundColor($r('app.color.news_list_item_bg'))
    .borderRadius(12)
    .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.navPathStuck.replacePath({ name: NAV_DESTS.ARTICLE, param: item.article })
    })
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Image($rawfile('empty_like.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .opacity(0.5)

      Text('暂无点赞')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 20 })

      Text('点赞的新闻会显示在这里')
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
        Text('清空点赞')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 16 })

        Text('确定要清空所有点赞吗？')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor($r('app.color.button_secondary_bg'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .onClick(() => { this.showClearDialog = false })

          Button('确定')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
            .backgroundColor($r('app.color.brand'))
            .fontColor(Color.White)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => { this.clearAllLikes() })
        }
        .width('100%')
      }
      .width(this.deviceType === DEVICE_TYPES.PHONE ? '80%' : '60%')
      .padding(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 28)
      .backgroundColor($r('app.color.dialog_bg'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.dialog_mask'))
    .onClick(() => { this.showClearDialog = false })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($rawfile('back.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 30)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => { this.navPathStuck.pop() })

          Text('我的点赞')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 26)
            .fontWeight(600)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 12 })

          Blank()

          if (this.likeList.length > 0) {
            Button('清空')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
              .backgroundColor($r('app.color.button_secondary_bg'))
              .fontColor($r('app.color.text_primary'))
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 40)
              .onClick(() => { this.showClearDialog = true })
          }
        }
        .width('100%')
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          top: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          bottom: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16
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
        } else if (this.likeList.length === 0) {
          this.EmptyStateBuilder()
        } else {
          List({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
            ForEach(this.likeList, (item: LikeItem) => {
              ListItem() {
                this.LikeItemBuilder(item)
              }
              .transition(TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut }))
            }, (item: LikeItem) => item.article.id + item.timestamp)
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
