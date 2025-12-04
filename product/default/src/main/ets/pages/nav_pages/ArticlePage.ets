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
import { ColorModChoseButton, FontSizeAdjustButton, NewsArticleView, favoriteManager, likeManager } from 'feature'
import { deviceInfo, commonEventManager } from '@kit.BasicServicesKit'
import { common, Want } from '@kit.AbilityKit'

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
  @Local isLiked: boolean = false

  /**
   * 检查收藏状态
   */
  async checkFavoriteStatus(): Promise<void> {
    this.isFavorite = await favoriteManager.isFavorite(this.article.id)
  }

  /**
   * 检查点赞状态
   */
  async checkLikeStatus(): Promise<void> {
    this.isLiked = await likeManager.isLiked(this.article.id)
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

  /**
   * 切换点赞状态
   */
  async toggleLike(): Promise<void> {
    if (this.isLiked) {
      const success = await likeManager.removeLike(this.article.id)
      if (success) {
        this.isLiked = false
        promptAction.openToast({ message: '已取消点赞', duration: 1500 })
      }
    } else {
      const success = await likeManager.addLike(this.article)
      if (success) {
        this.isLiked = true
        promptAction.openToast({ message: '已点赞', duration: 1500 })
      } else {
        promptAction.openToast({ message: '该文章已点赞', duration: 1500 })
      }
    }
  }

  /**
   * 分享文章
   */
  shareArticle(): void {
    const context = getContext(this) as common.UIAbilityContext
    const shareText = `【${this.article.title}】\n${this.article.url}\n\n来自鸿易讯`

    logger.info(`${LOG_TAG.MAIN_PAGE}开始分享文章: ${this.article.title}`)
    logger.info(`${LOG_TAG.MAIN_PAGE}分享内容: ${shareText}`)
    logger.info(`${LOG_TAG.MAIN_PAGE}文章URL: ${this.article.url}`)

    // 使用系统分享面板
    const want: Want = {
      action: 'ohos.want.action.sendData',
      type: 'text/plain',
      parameters: {
        'shareAbstract': this.article.title,
        'stream': shareText
      }
    }

    logger.info(`${LOG_TAG.MAIN_PAGE}Want配置: ${JSON.stringify(want)}`)

    context.startAbility(want).then(() => {
      logger.info(`${LOG_TAG.MAIN_PAGE}分享面板已打开`)
    }).catch((err: Error) => {
      logger.error(`${LOG_TAG.MAIN_PAGE}startAbility失败: ${err.message}`)
      logger.error(`${LOG_TAG.MAIN_PAGE}错误详情: ${JSON.stringify(err)}`)

      // 尝试备用方案：复制到剪贴板
      this.copyToClipboard(shareText)
    })
  }

  /**
   * 复制到剪贴板（备用方案）
   */
  copyToClipboard(text: string): void {
    import('@ohos.pasteboard').then((pasteboard) => {
      const pasteData = pasteboard.default.createData(pasteboard.default.MIMETYPE_TEXT_PLAIN, text)
      const systemPasteboard = pasteboard.default.getSystemPasteboard()
      systemPasteboard.setData(pasteData).then(() => {
        logger.info(`${LOG_TAG.MAIN_PAGE}已复制到剪贴板`)
        promptAction.openToast({ message: '链接已复制到剪贴板', duration: 2000 })
      }).catch((err: Error) => {
        logger.error(`${LOG_TAG.MAIN_PAGE}复制失败: ${err.message}`)
        promptAction.openToast({ message: '分享失败', duration: 1500 })
      })
    }).catch((err: Error) => {
      logger.error(`${LOG_TAG.MAIN_PAGE}导入pasteboard失败: ${err.message}`)
      promptAction.openToast({ message: '分享失败', duration: 1500 })
    })
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

        // 分享按钮 - 右上角
        Stack({ alignContent: Alignment.Center }) {
          Image($rawfile('share_icon.svg'))
            .width('50%')
            .height('50%')
            .fillColor($r('app.color.color_change_button_font'))
        }
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .shadow({ color: Color.Black, radius: 10 })
        .backgroundColor($r('app.color.color_change_button_background'))
        .onClick(() => { this.shareArticle() })
        .borderRadius(99)
        .position({ right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30, top: 60 })

        // 点赞按钮
        Stack({ alignContent: Alignment.Center }) {
          Image(this.isLiked ? $rawfile('like_filled.svg') : $rawfile('like_outline.svg'))
            .width('50%')
            .height('50%')
            .fillColor(this.isLiked ? '#FFD700' : $r('app.color.color_change_button_font'))
        }
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .shadow({ color: Color.Black, radius: 10 })
        .backgroundColor($r('app.color.color_change_button_background'))
        .onClick(() => { this.toggleLike() })
        .borderRadius(99)
        .position({ right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30, bottom: 280 })

        // 收藏按钮
        Stack({ alignContent: Alignment.Center }) {
          Image(this.isFavorite ? $rawfile('favorite_filled.svg') : $rawfile('favorite_outline.svg'))
            .width('50%')
            .height('50%')
            .fillColor(this.isFavorite ? '#FFFF0000' : $r('app.color.color_change_button_font'))
        }
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 35 : 45)
        .shadow({ color: Color.Black, radius: 10 })
        .backgroundColor($r('app.color.color_change_button_background'))
        .onClick(() => { this.toggleFavorite() })
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
      this.checkLikeStatus()
    })
    .width('100%')
    .height('100%')
  }
}