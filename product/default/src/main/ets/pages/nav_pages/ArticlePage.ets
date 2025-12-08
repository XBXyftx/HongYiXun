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
import { NewsArticleView, favoriteManager, likeManager, colorModManager, NoteEditor } from 'feature'
import { deviceInfo, pasteboard } from '@kit.BasicServicesKit'
import { CircleNavigation, CircleType } from '@abner/circle_navigation'

// 菜单项类型
interface MenuItemInfo {
  icon: Resource | string
  activeIcon?: Resource | string
  label: string
  isActive?: boolean
}

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
  @Local menuExpanded: boolean = false
  @Local showNoteEditor: boolean = false

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
   * 分享文章 - 复制链接到剪贴板
   */
  shareArticle(): void {
    const shareText = `【${this.article.title}】\n${this.article.url}\n\n来自鸿易讯`
    logger.info(`${LOG_TAG.MAIN_PAGE}分享文章: ${this.article.title}`)

    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
      const systemPasteboard = pasteboard.getSystemPasteboard()

      systemPasteboard.setData(pasteData).then(() => {
        logger.info(`${LOG_TAG.MAIN_PAGE}已复制到剪贴板`)
        promptAction.openToast({ message: '链接已复制，可粘贴分享', duration: 2000 })
      }).catch((err: Error) => {
        logger.error(`${LOG_TAG.MAIN_PAGE}复制失败: ${err.message}`)
        promptAction.openToast({ message: '复制失败', duration: 1500 })
      })
    } catch (error) {
      logger.error(`${LOG_TAG.MAIN_PAGE}分享失败: ${JSON.stringify(error)}`)
      promptAction.openToast({ message: '分享失败', duration: 1500 })
    }
  }

  /**
   * 获取菜单项配置
   */
  getMenuItems(): MenuItemInfo[] {
    return [
      {
        icon: $rawfile('note_icon.svg'),
        label: '笔记',
        isActive: false
      },
      {
        icon: $rawfile('color_mode.svg'),
        label: '深浅色',
        isActive: false
      },
      {
        icon: $rawfile('font_size.svg'),
        label: '字号',
        isActive: false
      },
      {
        icon: this.isLiked ? $rawfile('like_filled.svg') : $rawfile('like_outline.svg'),
        label: '点赞',
        isActive: this.isLiked
      },
      {
        icon: this.isFavorite ? $rawfile('favorite_filled.svg') : $rawfile('favorite_outline.svg'),
        label: '收藏',
        isActive: this.isFavorite
      },
      {
        icon: $rawfile('share_icon.svg'),
        label: '分享',
        isActive: false
      }
    ]
  }

  /**
   * 处理菜单项点击
   */
  handleMenuClick(position: number): void {
    switch (position) {
      case 0: // 笔记
        this.openNoteEditor()
        break
      case 1: // 深浅色切换
        this.toggleColorMode()
        break
      case 2: // 字号调整
        this.showFontSizeSheet()
        break
      case 3: // 点赞
        this.toggleLike()
        break
      case 4: // 收藏
        this.toggleFavorite()
        break
      case 5: // 分享
        this.shareArticle()
        break
    }
    // 点击后收起菜单
    this.menuExpanded = false
  }

  /**
   * 打开笔记编辑器
   */
  openNoteEditor(): void {
    this.showNoteEditor = true
  }

  /**
   * 切换深浅色模式
   */
  toggleColorMode(): void {
    // 0=浅色, 1=深色, 2=跟随系统，在浅色和深色之间切换
    if (this.userConfig.colorModel === 1) {
      this.userConfig.colorModel = 0
      colorModManager.setLightMod()
      promptAction.openToast({ message: '已切换为浅色模式', duration: 1500 })
    } else {
      this.userConfig.colorModel = 1
      colorModManager.setDarkMod()
      promptAction.openToast({ message: '已切换为深色模式', duration: 1500 })
    }
  }

  /**
   * 显示字号调整面板
   */
  showFontSizeSheet(): void {
    this.getUIContext().getPromptAction().openCustomDialog({
      builder: () => {
        this.FontSizeDialogBuilder()
      }
    })
  }

  @Builder
  FontSizeDialogBuilder() {
    Column({ space: 16 }) {
      Text('调整字号')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row() {
        Text('A')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Slider({
          value: this.userConfig.fontSize,
          min: 14,
          max: 24,
          step: 2
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.userConfig.fontSize = value
          })
        Text('A')
          .fontSize(24)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')

      Text(`当前字号: ${this.userConfig.fontSize}`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .padding(24)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .width('80%')
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

  /**
   * 圆形导航主按钮
   */
  @Builder
  menuTriggerBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.menuExpanded ? $rawfile('close.svg') : $rawfile('settings_icon.svg'))
        .width('50%')
        .height('50%')
        .fillColor($r('app.color.color_change_button_font'))
    }
    .width(this.deviceType === DEVICE_TYPES.PHONE ? 50 : 60)
    .height(this.deviceType === DEVICE_TYPES.PHONE ? 50 : 60)
    .backgroundColor($r('app.color.color_change_button_background'))
    .borderRadius(99)
    .shadow({ color: Color.Black, radius: 15, offsetY: 4 })
    .onClick(() => {
      this.menuExpanded = !this.menuExpanded
    })
  }

  /**
   * 圆形导航子菜单项
   */
  @Builder
  menuItemBuilder(position: number) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.getMenuItems()[position].icon)
          .width('50%')
          .height('50%')
          .fillColor(this.getMenuItemColor(position))
      }
      .width(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 48)
      .height(this.deviceType === DEVICE_TYPES.PHONE ? 40 : 48)
      .backgroundColor($r('app.color.color_change_button_background'))
      .borderRadius(99)
      .shadow({ color: Color.Black, radius: 8, offsetY: 2 })
      .onClick(() => {
        this.handleMenuClick(position)
      })
    }
  }

  /**
   * 获取菜单项颜色
   */
  getMenuItemColor(position: number): ResourceColor {
    if (position === 0) {
      return '#FF9500' // 笔记橙色
    }
    if (position === 3 && this.isLiked) {
      return '#FFD700' // 点赞激活色
    }
    if (position === 4 && this.isFavorite) {
      return '#FF0000' // 收藏激活色
    }
    return $r('app.color.color_change_button_font')
  }

  @Builder
  NoteEditorCoverBuilder() {
    NoteEditor({
      note: null,
      initialArticle: this.article,
      onClose: () => {
        this.showNoteEditor = false
      },
      onSaved: () => {
        promptAction.openToast({ message: '笔记已保存', duration: 1500 })
      }
    })
  }

  build() {
    NavDestination() {
      Stack() {
        this.ArticleContentBuilder()

        // 圆形导航菜单 - 右下角
        CircleNavigation({
          clickStatus: this.menuExpanded,
          quantity: 6,
          radius: this.deviceType === DEVICE_TYPES.PHONE ? 100 : 120,
          circleType: CircleType.LEFT_HALF,
          circleOffset: 0.15,
          duration: 300,
          parentLayout: () => {
            this.menuTriggerBuilder()
          },
          childLayout: (position: number) => {
            this.menuItemBuilder(position)
          }
        })
          .position({
            right: this.deviceType === DEVICE_TYPES.PHONE ? 20 : 30,
            bottom: this.deviceType === DEVICE_TYPES.PHONE ? 100 : 120
          })
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
    .bindContentCover(
      $$this.showNoteEditor,
      this.NoteEditorCoverBuilder(),
      {
        modalTransition: ModalTransition.DEFAULT
      }
    )
  }
}