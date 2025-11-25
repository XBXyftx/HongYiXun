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
import { AppStorageV2, promptAction } from '@kit.ArkUI'
import { DEVICE_TYPES, APP_STORAGE_KEYS, NewsArticle, UserConfigViewModel, logger, LOG_TAG } from 'common'
import { ColorModChoseButton, FontSizeAdjustButton, NewsArticleView, favoriteManager } from 'feature'
import { deviceInfo } from '@kit.BasicServicesKit'

@ComponentV2
export struct ArticlePage {
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!
  @Local article: NewsArticle = {
    id: '',
    title: '',
    date: '',
    url: '',
    content: []
  }
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local isFavorite: boolean = false

  /**
   * 检查收藏状态
   */
  async checkFavoriteStatus(): Promise<void> {
    this.isFavorite = await favoriteManager.isFavorite(this.article.id)
  }

  /**
   * 切换收藏状态
   */
  async toggleFavorite(): Promise<void> {
    if (this.isFavorite) {
      const success = await favoriteManager.removeFavorite(this.article.id)
      if (success) {
        this.isFavorite = false
        try {
          promptAction.openToast({ message: '已取消收藏', duration: 1500 })
        } catch (error) {
          promptAction.openToast({ message: '已取消收藏', duration: 1500 })
        }
      }
    } else {
      const success = await favoriteManager.addFavorite(this.article)
      if (success) {
        this.isFavorite = true
        try {
          promptAction.openToast({ message: '已添加到收藏', duration: 1500 })
        } catch (error) {
          promptAction.openToast({ message: '已添加到收藏', duration: 1500 })
        }
      } else {
        try {
          promptAction.openToast({ message: '该文章已在收藏中', duration: 1500 })
        } catch (error) {
          promptAction.openToast({ message: '该文章已在收藏中', duration: 1500 })
        }
      }
    }
  }

  @Builder
  ArticleContentBuilder() {
    Column() {
      Column() {
        NewsArticleView({ article: this.article, baseFontSize: this.userConfig.fontSize })
          .width('100%')
      }
      .width(this.deviceType === DEVICE_TYPES.PHONE ? '100%' : '90%')
      .height('100%')
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Stack() {
        this.ArticleContentBuilder()

        // 收藏按钮
        Stack({ alignContent: Alignment.Center }) {
          Image(this.isFavorite ? $rawfile('favorite_filled.svg') : $rawfile('favorite_outline.svg'))
            .width('50%')
            .height('50%')
            .fillColor(this.isFavorite ? '#FFFF0000' : $r('app.color.color_change_button_font'))
        }
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .shadow({
          color: Color.Black,
          radius: 10
        })
        .backgroundColor($r('app.color.color_change_button_background'))
        .onClick(() => {
          this.toggleFavorite()
        })
        .borderRadius(99)
        .position({ right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30, bottom: 220 })

        ColorModChoseButton()
          .position({ right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30, bottom: 160 })

        FontSizeAdjustButton()
          .position({ right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30, bottom: 100 })
      }

    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .hideToolBar(true)
    .borderRadius(8)
    .onReady((navDestinationContext: NavDestinationContext) => {
      this.article = navDestinationContext.pathInfo.param as NewsArticle
      this.checkFavoriteStatus()
    })
    .width('100%')
    .height('100%')
  }
}