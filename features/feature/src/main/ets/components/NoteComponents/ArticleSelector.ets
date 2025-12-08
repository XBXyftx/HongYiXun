/**
 * 文章选择器组件
 * 用于在笔记编辑器中搜索并选择关联文章
 */
import { DEVICE_TYPES, NewsArticle, LinkedArticleInfo } from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { searchManager } from '../../managers/SearchManager'
import { promptAction } from "@kit.ArkUI"

@ComponentV2
export struct ArticleSelector {
  /** 已关联的文章ID列表（用于过滤已选择的） */
  @Param linkedArticleIds: string[] = []
  /** 关闭回调 */
  @Event onClose: () => void = () => {}
  /** 选择文章回调 */
  @Event onSelect: (article: LinkedArticleInfo) => void = () => {}

  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local searchKeyword: string = ''
  @Local searchResults: NewsArticle[] = []
  @Local isSearching: boolean = false
  @Local hasSearched: boolean = false

  async aboutToAppear(): Promise<void> {
    await searchManager.init()
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

    const result = await searchManager.searchNews(this.searchKeyword)
    // 过滤掉已关联的文章
    this.searchResults = result.articles.filter(
      article => !this.linkedArticleIds.includes(article.id)
    )
    this.isSearching = false

    if (this.searchResults.length === 0) {
      promptAction.openToast({ message: '未找到可关联的文章', duration: 1500 })
    }
  }

  /**
   * 选择文章
   */
  selectArticle(article: NewsArticle): void {
    const linkedInfo: LinkedArticleInfo = {
      id: article.id,
      title: article.title,
      source: article.source || undefined,
      date: article.date,
      url: article.url
    }
    this.onSelect(linkedInfo)
    this.onClose()
  }


  @Builder
  HeaderBuilder() {
    Row() {
      // 关闭按钮
      Image($rawfile('close.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .fillColor($r('app.color.text_primary'))
        .onClick(() => this.onClose())

      Text('选择关联文章')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .margin({ top: 48 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  SearchInputBuilder() {
    Row() {
      // 搜索输入框
      Row() {
        Image($rawfile('search.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
          .fillColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索文章标题...', text: this.searchKeyword })
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
      left: 16,
      right: 16,
      top: 16,
      bottom: 12
    })
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
          Text(article.source || '')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)

          Text('·')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 5, right: 5 })

          Text(article.date || '')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
            .fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 添加按钮
      Text('+')
        .fontSize(24)
        .fontColor($r('app.color.brand'))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 10 })
    }
    .width('100%')
    .padding(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 18)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => {
      this.selectArticle(article)
    })
  }

  @Builder
  EmptyBuilder() {
    Column() {
      Text(this.hasSearched ? '未找到相关文章' : '输入关键词搜索文章')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      this.HeaderBuilder()
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
      } else if (this.searchResults.length > 0) {
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
          left: 16,
          right: 16,
          bottom: 16
        })
      } else {
        this.EmptyBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
