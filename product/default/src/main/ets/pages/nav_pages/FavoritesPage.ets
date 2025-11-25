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

import { DEVICE_TYPES, NAV_DESTS, APP_STORAGE_KEYS, FavoriteUpdateTrigger, logger, LOG_TAG } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { favoriteManager, FavoriteItem } from "feature"

@ComponentV2
export struct FavoritesPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack = AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local favoriteUpdateTrigger: FavoriteUpdateTrigger = 
    AppStorageV2.connect(FavoriteUpdateTrigger, APP_STORAGE_KEYS.FAVORITE_UPDATE_TRIGGER, () => new FavoriteUpdateTrigger())!
  @Local favoriteList: FavoriteItem[] = []
  @Local isLoading: boolean = true
  @Local showClearDialog: boolean = false

  async aboutToAppear(): Promise<void> {
    await this.loadFavorites()
  }

  /**
   * 监听收藏更新触发器
   */
  @Monitor('favoriteUpdateTrigger.trigger')
  async onFavoriteUpdate(): Promise<void> {
    logger.info(`${LOG_TAG.FAVORITE_MANAGER}检测到收藏更新，重新加载数据`)
    await this.loadFavorites()
  }

  /**
   * 加载收藏列表
   */
  async loadFavorites(): Promise<void> {
    this.isLoading = true
    try {
      this.favoriteList = await favoriteManager.getFavoriteList()
      logger.info(`${LOG_TAG.FAVORITE_MANAGER}加载收藏列表成功: ${this.favoriteList.length}条`)
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}加载收藏列表失败: ${JSON.stringify(error)}`)
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 删除单条收藏
   */
  async deleteFavoriteItem(articleId: string): Promise<void> {
    const success = await favoriteManager.removeFavorite(articleId)
    if (success) {
      try {
        promptAction.openToast({ message: '已取消收藏', duration: 1500 })
      } catch (error) {
        promptAction.openToast({ message: '已取消收藏', duration: 1500 })
      }
    }
  }

  /**
   * 清空所有收藏
   */
  async clearAllFavorites(): Promise<void> {
    const success = await favoriteManager.clearAllFavorites()
    if (success) {
      this.showClearDialog = false
      try {
        promptAction.openToast({ message: '已清空所有收藏', duration: 1500 })
      } catch (error) {
        promptAction.openToast({ message: '已清空所有收藏', duration: 1500 })
      }
    }
  }

  /**
   * 格式化时间显示
   */
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
  FavoriteItemBuilder(item: FavoriteItem) {
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
          this.deleteFavoriteItem(item.article.id)
        })
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
      Image($rawfile('empty_favorite.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 120 : 160)
        .opacity(0.5)
      
      Text('暂无收藏')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 20)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 20 })
      
      Text('收藏的新闻会显示在这里')
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
        Text('清空收藏')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 16 })
        
        Text('确定要清空所有收藏吗？')
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
              this.clearAllFavorites()
            })
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
    .onClick(() => {
      this.showClearDialog = false
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

          Text('我的收藏')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 26)
            .fontWeight(600)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 12 })
          
          Blank()
          
          if (this.favoriteList.length > 0) {
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

        // 收藏列表
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
              .height(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 50)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.favoriteList.length === 0) {
          this.EmptyStateBuilder()
        } else {
          List({ space: this.deviceType === DEVICE_TYPES.PHONE ? 12 : 16 }) {
            ForEach(this.favoriteList, (item: FavoriteItem) => {
              ListItem() {
                this.FavoriteItemBuilder(item)
              }
              .transition(TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut }))
            }, (item: FavoriteItem) => item.article.id + item.timestamp)
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
