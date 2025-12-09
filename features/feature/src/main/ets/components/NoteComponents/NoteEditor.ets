/**
 * 笔记编辑器组件
 * 支持图文混排编辑、关联文章、保存和导出PDF
 */
import {
  DEVICE_TYPES,
  NoteItem,
  NoteContentBlock,
  NoteContentType,
  LinkedArticleInfo,
  NewsArticle,
  NAV_DESTS,
  APP_STORAGE_KEYS,
  logger,
  LOG_TAG
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { noteManager } from '../../managers/NoteManager'
import { promptAction, AppStorageV2 } from "@kit.ArkUI"
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { searchManager, SearchResult } from '../../managers/SearchManager'

/**
 * 可观察的内容块
 */
@ObservedV2
export class ObservableContentBlock {
  @Trace type: NoteContentType = NoteContentType.TEXT
  @Trace value: string = ''

  constructor(type: NoteContentType, value: string) {
    this.type = type
    this.value = value
  }
}

/**
 * 可观察的关联文章
 */
@ObservedV2
export class ObservableLinkedArticle {
  @Trace id: string = ''
  @Trace title: string = ''
  @Trace source: string = ''
  @Trace date: string = ''
  @Trace url: string = ''

  constructor(info?: LinkedArticleInfo) {
    if (info) {
      this.id = info.id
      this.title = info.title
      this.source = info.source || ''
      this.date = info.date
      this.url = info.url
    }
  }

  toLinkedArticleInfo(): LinkedArticleInfo {
    return {
      id: this.id,
      title: this.title,
      source: this.source || undefined,
      date: this.date,
      url: this.url
    }
  }
}

/**
 * 笔记编辑器组件
 */
@ComponentV2
export struct NoteEditor {
  @Param note: NoteItem | null = null
  @Param initialArticle: NewsArticle | null = null
  @Param isReadOnly: boolean = false
  @Event onClose: () => void = () => {}
  @Event onSaved: () => void = () => {}
  @Event onEdit: () => void = () => {}

  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!

  // 编辑状态
  @Local noteId: string = ''
  @Local title: string = ''
  @Local currentText: string = ''
  @Local isSaving: boolean = false
  @Local isInitialized: boolean = false

  // 使用可观察数组
  @Local contentBlocks: ObservableContentBlock[] = []
  @Local linkedArticles: ObservableLinkedArticle[] = []

  // 搜索相关 - 使用触发器机制
  @Local showSearchPanel: boolean = false
  @Local searchKeyword: string = ''
  @Local searchResults: NewsArticle[] = []
  @Local isSearching: boolean = false
  @Local hasSearched: boolean = false
  @Local refreshTrigger: number = 0


  async aboutToAppear(): Promise<void> {
    await noteManager.init()

    if (this.note) {
      this.noteId = this.note.id
      this.title = this.note.title
      // 转换为可观察对象
      this.contentBlocks = this.note.content.map(b => new ObservableContentBlock(b.type, b.value))
      this.linkedArticles = this.note.linkedArticles.map(a => new ObservableLinkedArticle(a))
      this.currentText = this.note.content
        .filter(b => b.type === NoteContentType.TEXT)
        .map(b => b.value)
        .join('\n')
    } else if (this.initialArticle) {
      const linkedArticle = new ObservableLinkedArticle({
        id: this.initialArticle.id,
        title: this.initialArticle.title,
        source: this.initialArticle.source || undefined,
        date: this.initialArticle.date,
        url: this.initialArticle.url
      })
      this.linkedArticles = [linkedArticle]
    }
    this.isInitialized = true
    this.refreshTrigger++
  }

  async saveNote(): Promise<void> {
    if (!this.title.trim()) {
      promptAction.openToast({ message: '请输入笔记标题', duration: 1500 })
      return
    }

    this.isSaving = true
    const blocks: NoteContentBlock[] = []
    if (this.currentText.trim()) {
      blocks.push({ type: NoteContentType.TEXT, value: this.currentText.trim() })
    }
    // 添加图片块
    this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE).forEach(b => {
      blocks.push({ type: b.type, value: b.value })
    })

    const noteData: NoteItem = {
      id: this.noteId,
      title: this.title.trim(),
      content: blocks,
      linkedArticles: this.linkedArticles.map(a => a.toLinkedArticleInfo()),
      createTime: this.note?.createTime || Date.now(),
      updateTime: Date.now()
    }

    const success = await noteManager.saveNote(noteData)
    this.isSaving = false

    if (success) {
      promptAction.openToast({ message: '保存成功', duration: 1500 })
      this.onSaved()
      this.onClose()
    } else {
      promptAction.openToast({ message: '保存失败', duration: 1500 })
    }
  }

  async selectImage(): Promise<void> {
    // 计算当前已有图片数量
    const currentImageCount = this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE).length
    const maxImages = 10
    const remainingSlots = maxImages - currentImageCount

    if (remainingSlots <= 0) {
      promptAction.openToast({ message: '最多添加10张图片', duration: 1500 })
      return
    }

    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const result = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: remainingSlots
      })
      if (result.photoUris && result.photoUris.length > 0) {
        const newBlocks = result.photoUris.map(uri => new ObservableContentBlock(NoteContentType.IMAGE, uri))
        this.contentBlocks = [...this.contentBlocks, ...newBlocks]
        this.refreshTrigger++
        const addedCount = result.photoUris.length
        promptAction.openToast({ message: `已添加${addedCount}张图片`, duration: 1000 })
      }
    } catch (error) {
      promptAction.openToast({ message: '选择图片失败', duration: 1500 })
    }
  }

  removeImage(index: number): void {
    const imageBlocks = this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE)
    if (index >= 0 && index < imageBlocks.length) {
      const targetValue = imageBlocks[index].value
      this.contentBlocks = this.contentBlocks.filter(b =>
        !(b.type === NoteContentType.IMAGE && b.value === targetValue)
      )
      this.refreshTrigger++
    }
  }

  removeLinkedArticle(articleId: string): void {
    this.linkedArticles = this.linkedArticles.filter(a => a.id !== articleId)
    this.refreshTrigger++
  }

  goToArticle(article: ObservableLinkedArticle): void {
    const newsArticle: NewsArticle = {
      id: article.id,
      title: article.title,
      source: article.source,
      date: article.date,
      url: article.url,
      content: []
    }
    this.onClose()
    this.navPathStuck.pushPath({ name: NAV_DESTS.ARTICLE, param: newsArticle })
  }

  async exportNote(): Promise<void> {
    promptAction.openToast({ message: '导出功能开发中', duration: 1500 })
  }

  openSearchPanel(): void {
    this.showSearchPanel = true
    this.searchKeyword = ''
    this.searchResults = []
    this.hasSearched = false
    this.refreshTrigger++
  }

  closeSearchPanel(): void {
    this.showSearchPanel = false
    this.searchKeyword = ''
    this.searchResults = []
    this.hasSearched = false
    this.refreshTrigger++
  }

  async searchArticles(): Promise<void> {
    if (!this.searchKeyword.trim()) return
    this.isSearching = true
    this.hasSearched = true
    this.refreshTrigger++
    await searchManager.init()
    const result: SearchResult = await searchManager.searchNews(this.searchKeyword)
    this.searchResults = result.articles.filter(
      article => !this.linkedArticles.some(a => a.id === article.id)
    )
    this.isSearching = false
    this.refreshTrigger++
  }

  selectArticleToLink(article: NewsArticle): void {
    if (this.linkedArticles.some(a => a.id === article.id)) {
      promptAction.openToast({ message: '该文章已关联', duration: 1500 })
      return
    }
    if (this.linkedArticles.length >= 5) {
      promptAction.openToast({ message: '最多关联5篇文章', duration: 1500 })
      return
    }
    const newLinked = new ObservableLinkedArticle({
      id: article.id,
      title: article.title,
      source: article.source || undefined,
      date: article.date,
      url: article.url
    })
    this.linkedArticles = [...this.linkedArticles, newLinked]
    this.refreshTrigger++
    promptAction.openToast({ message: '已添加关联文章', duration: 1000 })
    this.closeSearchPanel()
  }


  @Builder
  HeaderBuilder() {
    Row() {
      Image($rawfile('close.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .fillColor($r('app.color.text_primary'))
        .onClick(() => this.onClose())

      Text(this.isReadOnly ? '查看笔记' : (this.noteId ? '编辑笔记' : '新建笔记'))
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      if (this.isReadOnly) {
        Button('编辑')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand'))
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 38)
          .borderRadius(16)
          .onClick(() => this.onEdit())
      } else {
        Image($rawfile('share_icon.svg'))
          .width(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
          .fillColor($r('app.color.text_primary'))
          .margin({ right: 16 })
          .onClick(() => this.exportNote())

        Button('保存')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand'))
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 38)
          .borderRadius(16)
          .enabled(!this.isSaving)
          .onClick(() => this.saveNote())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    // .backgroundColor($r('app.color.card_bg'))
  }


  @Builder
  LinkedArticlesBuilder() {
    Column() {
      Row() {
        Text('关联文章')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Text(`${this.linkedArticles.length}/5`)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })

        Blank()

        if (!this.isReadOnly && this.linkedArticles.length < 5 && !this.showSearchPanel) {
          Row() {
            Text('+')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
              .fontColor($r('app.color.brand'))
              .fontWeight(FontWeight.Bold)
            Text('添加')
              .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
              .fontColor($r('app.color.brand'))
              .margin({ left: 4 })
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .borderWidth(1)
          .borderColor($r('app.color.brand'))
          .onClick(() => this.openSearchPanel())
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.showSearchPanel && !this.isReadOnly) {
        this.InlineSearchPanelBuilder()
      }

      if (this.linkedArticles.length > 0) {
        ForEach(this.linkedArticles, (article: ObservableLinkedArticle) => {
          Row() {
            Column() {
              Text(article.title)
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${article.source || ''} · ${article.date}`)
                .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 11 : 13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .onClick(() => this.goToArticle(article))

            if (!this.isReadOnly) {
              Image($rawfile('close.svg'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.text_secondary'))
                .margin({ left: 8 })
                .onClick(() => this.removeLinkedArticle(article.id))
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.news_list_item_bg'))
          .borderRadius(8)
          .margin({ bottom: 8 })
        }, (article: ObservableLinkedArticle) => article.id + this.refreshTrigger)
      } else if (!this.showSearchPanel) {
        Text(this.isReadOnly ? '暂无关联文章' : '暂无关联文章，点击"添加"按钮搜索')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
          .fontColor($r('app.color.text_secondary'))
          .padding(12)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .margin({ bottom: 16 })
  }


  @Builder
  InlineSearchPanelBuilder() {
    Column() {
      Row() {
        Image($rawfile('search.svg'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.text_secondary'))
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索文章标题...', text: this.searchKeyword })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .placeholderColor($r('app.color.text_secondary'))
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 0, right: 0, top: 6, bottom: 6 })
          .height(36)
          .onChange((value: string) => { this.searchKeyword = value })
          .onSubmit(() => { this.searchArticles() })

        Text('搜索')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
          .fontColor($r('app.color.brand'))
          .margin({ left: 8 })
          .onClick(() => this.searchArticles())

        Text('取消')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 12 })
          .onClick(() => this.closeSearchPanel())
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .height(44)
      .backgroundColor($r('app.color.news_list_item_bg'))
      .borderRadius(22)
      .margin({ bottom: 12 })

      if (this.isSearching) {
        Row() {
          LoadingProgress().width(24).height(24)
          Text('搜索中...').fontSize(13).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        Column() {
          ForEach(this.searchResults.slice(0, 5), (article: NewsArticle) => {
            Row() {
              Column() {
                Text(article.title)
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${article.source || ''} · ${article.date}`)
                  .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 11 : 13)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text('+')
                .fontSize(20)
                .fontColor($r('app.color.brand'))
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.news_list_item_bg'))
            .borderRadius(8)
            .margin({ bottom: 6 })
            .onClick(() => this.selectArticleToLink(article))
          }, (article: NewsArticle) => article.id + this.refreshTrigger)
        }
      } else if (this.hasSearched) {
        Text('未找到相关文章')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
  }


  @Builder
  ImagePreviewBuilder() {
    if (this.contentBlocks.some(b => b.type === NoteContentType.IMAGE)) {
      Column() {
        Text('已添加图片')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(
            this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE),
            (block: ObservableContentBlock, index: number) => {
              Stack({ alignContent: Alignment.TopEnd }) {
                Image(block.value)
                  .width(80)
                  .height(80)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .alt($rawfile('image_icon.svg'))

                if (!this.isReadOnly) {
                  Image($rawfile('close.svg'))
                    .width(18)
                    .height(18)
                    .fillColor(Color.White)
                    .backgroundColor('#80000000')
                    .borderRadius(9)
                    .padding(2)
                    .onClick(() => this.removeImage(index))
                }
              }
              .margin({ right: 8, bottom: 8 })
            },
            (block: ObservableContentBlock, index: number) => `img_${index}_${block.value}_${this.refreshTrigger}`
          )
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(12)
      .margin({ bottom: 16 })
    }
  }


  @Builder
  EditorBuilder() {
    Column() {
      if (this.isReadOnly) {
        Text(this.title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ top: 8, bottom: 8 })

        Divider()
          .color($r('app.color.text_secondary'))
          .opacity(0.3)
          .margin({ top: 4, bottom: 12 })

        Text(this.currentText || '暂无内容')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 17)
          .fontColor(this.currentText ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          .width('100%')
      } else {
        TextInput({ placeholder: '请输入笔记标题', text: this.title })
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 0, top: 8, bottom: 8 })
          .height(this.deviceType === DEVICE_TYPES.PHONE ? 48 : 56)
          .onChange((value: string) => { this.title = value })

        Divider()
          .color($r('app.color.text_secondary'))
          .opacity(0.3)
          .margin({ top: 4, bottom: 12 })

        TextArea({ placeholder: '开始记录你的想法...', text: this.currentText })
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 17)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .padding({ left: 0, right: 0, top: 8, bottom: 8 })
          .constraintSize({ minHeight: 200 })
          .onChange((value: string) => { this.currentText = value })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    // .borderRadius(12)
  }

  @Builder
  ToolbarBuilder() {
    if (!this.isReadOnly) {
      Row() {
        Row() {
          Image($rawfile('image_icon.svg'))
            .width(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
            .height(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
            .fillColor($r('app.color.text_primary'))
          Text('添加图片')
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 6 })
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(20)
        .onClick(() => this.selectImage())
      }
      .margin({bottom:30})
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Start)
    }
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column() {
          this.LinkedArticlesBuilder()
          this.ImagePreviewBuilder()
          this.EditorBuilder()
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.ToolbarBuilder()
    }
    // .expandSafeArea()
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
