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
import { AppStorageV2 } from '@kit.ArkUI'
import { DEVICE_TYPES, GET_USER_CONFIG, NewsArticle, UserConfigViewModel } from 'common'
import { ColorModChoseButton, FontSizeAdjustButton, NewsArticleView } from 'feature'
import { deviceInfo } from '@kit.BasicServicesKit'

@ComponentV2
export struct ArticlePage {
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, GET_USER_CONFIG, () => new UserConfigViewModel())!
  @Local article: NewsArticle = {
    id: '',
    title: '',
    date: '',
    url: '',
    content: []
  }
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET

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
    })
    .width('100%')
    .height('100%')
  }
}