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
  APP_STORAGE_KEYS
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { noteManager } from '../../managers/NoteManager'
import { promptAction, AppStorageV2 } from "@kit.ArkUI"
import { picker } from '@kit.CoreFileKit'

/**
 * 笔记编辑器组件
 */
@ComponentV2
export struct NoteEditor {
  /** 要编辑的笔记（新建时为空） */
  @Param note: NoteItem | null = null
  /** 初始关联的文章（从文章页进入时传入） */
  @Param initialArticle: NewsArticle | null = null
  /** 关闭回调 */
  @Event onClose: () => void = () => {}
  /** 保存成功回调 */
  @Event onSaved: () => void = () => {}

  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local navPathStuck: NavPathStack =
    AppStorageV2.connect(NavPathStack, APP_STORAGE_KEYS.NAV_PATH_STUCK, () => new NavPathStack())!

  // 编辑状态
  @Local noteId: string = ''
  @Local title: string = ''
  @Local contentBlocks: NoteContentBlock[] = []
  @Local linkedArticles: LinkedArticleInfo[] = []
  @Local currentText: string = ''
  @Local isSaving: boolean = false
  @Local isInitialized: boolean = false

  async aboutToAppear(): Promise<void> {
    await noteManager.init()

    if (this.note) {
      // 编辑现有笔记
      this.noteId = this.note.id
      this.title = this.note.title
      this.contentBlocks = [...this.note.content]
      this.linkedArticles = [...this.note.linkedArticles]
      // 将内容块转换为可编辑文本
      this.currentText = this.contentBlocks
        .filter(b => b.type === NoteContentType.TEXT)
        .map(b => b.value)
        .join('\n')
    } else if (this.initialArticle) {
      // 从文章页进入，自动关联当前文章
      this.linkedArticles = [{
        id: this.initialArticle.id,
        title: this.initialArticle.title,
        source: this.initialArticle.source || undefined,
        date: this.initialArticle.date,
        url: this.initialArticle.url
      }]
    }
    this.isInitialized = true
  }


  /**
   * 保存笔记
   */
  async saveNote(): Promise<void> {
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入笔记标题', duration: 1500 })
      return
    }

    this.isSaving = true

    // 构建内容块
    const blocks: NoteContentBlock[] = []
    if (this.currentText.trim()) {
      blocks.push({
        type: NoteContentType.TEXT,
        value: this.currentText.trim()
      })
    }
    // 保留图片块
    this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE).forEach(b => blocks.push(b))

    const noteData: NoteItem = {
      id: this.noteId,
      title: this.title.trim(),
      content: blocks,
      linkedArticles: this.linkedArticles,
      createTime: this.note?.createTime || Date.now(),
      updateTime: Date.now()
    }

    const success = await noteManager.saveNote(noteData)
    this.isSaving = false

    if (success) {
      promptAction.showToast({ message: '保存成功', duration: 1500 })
      this.onSaved()
      this.onClose()
    } else {
      promptAction.showToast({ message: '保存失败', duration: 1500 })
    }
  }

  /**
   * 从相册选择图片
   */
  async selectImage(): Promise<void> {
    try {
      const photoPicker = new picker.PhotoViewPicker()
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })

      if (result.photoUris && result.photoUris.length > 0) {
        const imageUri = result.photoUris[0]
        this.contentBlocks.push({
          type: NoteContentType.IMAGE,
          value: imageUri
        })
        promptAction.showToast({ message: '图片已添加', duration: 1000 })
      }
    } catch (error) {
      promptAction.showToast({ message: '选择图片失败', duration: 1500 })
    }
  }

  /**
   * 删除图片
   */
  removeImage(index: number): void {
    const imageBlocks = this.contentBlocks.filter(b => b.type === NoteContentType.IMAGE)
    if (index >= 0 && index < imageBlocks.length) {
      const targetValue = imageBlocks[index].value
      this.contentBlocks = this.contentBlocks.filter(b => 
        !(b.type === NoteContentType.IMAGE && b.value === targetValue)
      )
    }
  }

  /**
   * 移除关联文章
   */
  removeLinkedArticle(articleId: string): void {
    this.linkedArticles = this.linkedArticles.filter(a => a.id !== articleId)
  }

  /**
   * 跳转到关联文章
   */
  goToArticle(article: LinkedArticleInfo): void {
    const newsArticle: NewsArticle = {
      id: article.id,
      title: article.title,
      source: article.source,
      date: article.date,
      url: article.url,
      content: []
    }
    this.onClose()
    this.navPathStuck.pushPath({
      name: NAV_DESTS.ARTICLE,
      param: newsArticle
    })
  }

  /**
   * 导出PDF（简化实现：复制内容到剪贴板）
   */
  async exportNote(): Promise<void> {
    const content = `${this.title}\n\n${this.currentText}\n\n关联文章：\n${
      this.linkedArticles.map(a => `- ${a.title}`).join('\n')
    }`
    promptAction.showToast({ message: '导出功能开发中', duration: 1500 })
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

      Text(this.noteId ? '编辑笔记' : '新建笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 导出按钮
      Image($rawfile('share_icon.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 22 : 26)
        .fillColor($r('app.color.text_primary'))
        .margin({ right: 16 })
        .onClick(() => this.exportNote())

      // 保存按钮
      Button('保存')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand'))
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 38)
        .borderRadius(16)
        .enabled(!this.isSaving)
        .onClick(() => this.saveNote())
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor($r('app.color.card_bg'))
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
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.linkedArticles.length > 0) {
        ForEach(this.linkedArticles, (article: LinkedArticleInfo) => {
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

            Image($rawfile('close.svg'))
              .width(16)
              .height(16)
              .fillColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
              .onClick(() => this.removeLinkedArticle(article.id))
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.news_list_item_bg'))
          .borderRadius(8)
          .margin({ bottom: 8 })
        }, (article: LinkedArticleInfo) => article.id)
      } else {
        Text('暂无关联文章')
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
          .fontColor($r('app.color.text_secondary'))
          .padding(12)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .margin({ bottom: 16 })
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
            (block: NoteContentBlock, index: number) => {
              Stack({ alignContent: Alignment.TopEnd }) {
                Image(block.value)
                  .width(80)
                  .height(80)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)

                Image($rawfile('close.svg'))
                  .width(18)
                  .height(18)
                  .fillColor(Color.White)
                  .backgroundColor('#80000000')
                  .borderRadius(9)
                  .padding(2)
                  .onClick(() => this.removeImage(index))
              }
              .margin({ right: 8, bottom: 8 })
            },
            (block: NoteContentBlock, index: number) => `img_${index}_${block.value}`
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
      // 标题输入
      TextInput({ placeholder: '请输入笔记标题', text: this.title })
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 18 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .padding(0)
        .onChange((value: string) => {
          this.title = value
        })

      Divider()
        .color($r('app.color.text_secondary'))
        .opacity(0.3)
        .margin({ top: 12, bottom: 12 })

      // 内容输入
      TextArea({ placeholder: '开始记录你的想法...', text: this.currentText })
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 15 : 17)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .padding(0)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.currentText = value
        })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }

  @Builder
  ToolbarBuilder() {
    Row() {
      // 添加图片按钮
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
    .width('100%')
    .padding(16)
    .justifyContent(FlexAlign.Start)
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
        .padding({
          left: 16,
          right: 16,
          top: 16,
          bottom: 16
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      this.ToolbarBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
