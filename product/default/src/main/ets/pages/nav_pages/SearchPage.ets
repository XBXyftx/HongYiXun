/**
 * 搜索页面
 * 使用共享元素转场从搜索栏展开
 */
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { DEVICE_TYPES, APP_STORAGE_KEYS, NewsArticle, NAV_DESTS } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { searchManager, SearchHistoryItem, SEARCH_BAR_SHARED_ID } from "feature"

@ComponentV2
export struct SearchPage {
  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!
  @Local searchKeyword: string = ''
  @Local searchHistory: SearchHistoryItem[] = []
  @Local searchResults: NewsArticle[] = []
  @Local isSearching: boolean = false
  @Local hasSearched: boolean = false
  @Local isInitialized: boolean = false

  async aboutToAppear(): Promise<void> {
    if (!this.isInitialized) {
      await searchManager.init()
      this.isInitialized = true
    }
    this.searchHistory = await searchManager.getSearchHistory()
  }

  /**
   * 执行搜索
   */
  async doSearch(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      return
    }

    this.isSearching = true
    this.hasSearched = true

    // 添加到搜索历史
    await searchManager.addSearchHistory(this.searchKeyword)
    this.searchHistory = await searchManager.getSearchHistory()

    // 执行搜索
    const result = await searchManager.searchNews(this.searchKeyword)
    this.searchResults = result.articles
    this.isSearching = false

    if (result.total === 0) {
      promptAction.showToast({ message: '未找到相关新闻', duration: 1500 })
    } else {
      promptAction.showToast({ message: `找到 ${result.total} 条相关新闻`, duration: 1500 })
    }
  }


  /**
   * 点击历史记录搜索
   */
  async searchFromHistory(keyword: string): Promise<void> {
    this.searchKeyword = keyword
    await this.doSearch()
  }

  /**
   * 删除历史记录
   */
  async deleteHistory(keyword: string): Promise<void> {
    await searchManager.removeSearchHistory(keyword)
    this.searchHistory = await searchManager.getSearchHistory()
  }

  /**
   * 清空历史记录
   */
  async clearHistory(): Promise<void> {
    await searchManager.clearSearchHistory()
    this.searchHistory = []
  }

  @Builder
  SearchInputBuilder() {
    Row() {
      // 返回按钮
      Image($rawfile('back.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .fillColor($r('app.color.text_primary'))
        .margin({ right: 12 })
        .onClick(() => {
          this.navPathStuck.pop()
        })

      // 搜索输入框
      Row() {
        Image($r('app.media.search'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索本地新闻...', text: this.searchKeyword })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .placeholderColor($r('app.color.text_secondary'))
          .fontColor($r('app.color.text_primary'))
          .onChange((value: string) => {
            this.searchKeyword = value
          })
          .onSubmit(() => {
            this.doSearch()
          })

        if (this.searchKeyword.length > 0) {
          Image($rawfile('close.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
            .fillColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.searchKeyword = ''
              this.hasSearched = false
              this.searchResults = []
            })
        }
      }
      .layoutWeight(1)
      .height(this.deviceType === DEVICE_TYPES.PHONE ? 44 : 52)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(22)
      .geometryTransition(SEARCH_BAR_SHARED_ID)
      .transition(TransitionEffect.OPACITY.animation({ duration: 350, curve: Curve.Friction }))

      // 搜索按钮
      Text('搜索')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor($r('app.color.brand'))
        .margin({ left: 12 })
        .onClick(() => {
          this.doSearch()
        })
    }
    .width('100%')
    .padding({
      left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
      right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
      top: 48,
      bottom: 12
    })
  }


  @Builder
  SearchHistoryBuilder() {
    Column() {
      // 标题栏
      Row() {
        Text('搜索历史')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        if (this.searchHistory.length > 0) {
          Text('清空')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
            .fontColor($r('app.color.text_secondary'))
            .onClick(() => {
              this.clearHistory()
            })
        }
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 历史记录列表
      if (this.searchHistory.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.searchHistory, (item: SearchHistoryItem) => {
            Row() {
              Text(item.keyword)
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Image($rawfile('close.svg'))
                .width(14)
                .height(14)
                .fillColor($r('app.color.text_secondary'))
                .margin({ left: 6 })
                .onClick(() => {
                  this.deleteHistory(item.keyword)
                })
            }
            .padding({ left: 12, right: 8, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.searchFromHistory(item.keyword)
            })
          }, (item: SearchHistoryItem) => item.keyword + item.timestamp)
        }
      } else {
        Text('暂无搜索历史')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .padding({
      left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
      right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
      top: 16
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SearchResultBuilder() {
    Column() {
      Text(`搜索结果 (${this.searchResults.length})`)
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          top: 16,
          bottom: 12
        })

      if (this.searchResults.length > 0) {
        List({ space: 12 }) {
          ForEach(this.searchResults, (article: NewsArticle) => {
            ListItem() {
              this.ArticleItemBuilder(article)
            }
          }, (article: NewsArticle) => article.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24,
          right: this.deviceType === DEVICE_TYPES.PHONE ? 16 : 24
        })
      } else {
        Column() {
          Text('未找到相关新闻')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }


  @Builder
  ArticleItemBuilder(article: NewsArticle) {
    Row() {
      Column() {
        Text(article.title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 18)
          .fontWeight(500)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor($r('app.color.text_primary'))

        Row() {
          Text(article.source ?? '')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)

          Text('·')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 5, right: 5 })

          Text(article.date ?? '')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
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
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => {
      this.navPathStuck.pushPath({
        name: NAV_DESTS.ARTICLE,
        param: article
      })
    })
  }

  build() {
    NavDestination() {
      Column() {
        this.SearchInputBuilder()

        if (this.isSearching) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
            Text('搜索中...')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 12 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.hasSearched) {
          this.SearchResultBuilder()
        } else {
          Scroll() {
            this.SearchHistoryBuilder()
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}