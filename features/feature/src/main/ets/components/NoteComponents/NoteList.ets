/**
 * 笔记列表组件
 * 显示用户的所有笔记，支持新建、编辑和删除
 */
import {
  DEVICE_TYPES,
  NoteItem,
  NoteContentType,
  APP_STORAGE_KEYS,
  NoteUpdateTrigger
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { noteManager } from '../../managers/NoteManager'
import { promptAction, AppStorageV2 } from "@kit.ArkUI"
import { NoteEditor } from './NoteEditor'

@ComponentV2
export struct NoteList {
  /** 关闭回调 */
  @Event onClose: () => void = () => {}

  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local noteUpdateTrigger: NoteUpdateTrigger =
    AppStorageV2.connect(NoteUpdateTrigger, APP_STORAGE_KEYS.NOTE_UPDATE_TRIGGER, () => new NoteUpdateTrigger())!
  @Local notes: NoteItem[] = []
  @Local isLoading: boolean = true
  @Local showEditor: boolean = false
  @Local editingNote: NoteItem | null = null

  async aboutToAppear(): Promise<void> {
    await noteManager.init()
    await this.loadNotes()
  }

  @Monitor('noteUpdateTrigger.trigger')
  async onNoteUpdate(): Promise<void> {
    await this.loadNotes()
  }

  async loadNotes(): Promise<void> {
    this.isLoading = true
    this.notes = await noteManager.getNoteList()
    this.isLoading = false
  }

  /**
   * 新建笔记
   */
  createNewNote(): void {
    this.editingNote = null
    this.showEditor = true
  }

  /**
   * 编辑笔记
   */
  editNote(note: NoteItem): void {
    this.editingNote = note
    this.showEditor = true
  }


  /**
   * 删除笔记
   */
  async deleteNote(note: NoteItem): Promise<void> {
    promptAction.showDialog({
      title: '删除笔记',
      message: `确定要删除"${note.title}"吗？`,
      buttons: [
        { text: '取消', color: $r('app.color.text_secondary') },
        { text: '删除', color: '#FF4444' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        const success = await noteManager.deleteNote(note.id)
        if (success) {
          promptAction.showToast({ message: '已删除', duration: 1500 })
        }
      }
    })
  }

  /**
   * 格式化时间
   */
  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now.getTime() - timestamp

    if (diff < 60000) {
      return '刚刚'
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`
    } else if (date.getFullYear() === now.getFullYear()) {
      return `${date.getMonth() + 1}月${date.getDate()}日`
    } else {
      return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
    }
  }

  /**
   * 获取笔记预览文本
   */
  getPreviewText(note: NoteItem): string {
    const textBlocks = note.content.filter(b => b.type === NoteContentType.TEXT)
    if (textBlocks.length > 0) {
      return textBlocks[0].value.substring(0, 100)
    }
    const imageCount = note.content.filter(b => b.type === NoteContentType.IMAGE).length
    if (imageCount > 0) {
      return `[${imageCount}张图片]`
    }
    return '暂无内容'
  }

  @Builder
  HeaderBuilder() {
    Row() {
      // 返回按钮
      Image($rawfile('back.svg'))
        .width(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 24 : 28)
        .fillColor($r('app.color.text_primary'))
        .onClick(() => this.onClose())

      Text('我的笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 12 })
        .layoutWeight(1)

      // 新建按钮
      Button('新建')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand'))
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 38)
        .borderRadius(16)
        .onClick(() => this.createNewNote())
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
  NoteItemBuilder(note: NoteItem) {
    Column() {
      Row() {
        Text(note.title)
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.formatTime(note.updateTime))
          .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')

      Text(this.getPreviewText(note))
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')

      if (note.linkedArticles.length > 0) {
        Row() {
          Image($rawfile('link_icon.svg'))
            .width(14)
            .height(14)
            .fillColor($r('app.color.text_secondary'))

          Text(`关联${note.linkedArticles.length}篇文章`)
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 11 : 13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 4 })
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .onClick(() => this.editNote(note))
    .gesture(
      LongPressGesture()
        .onAction(() => this.deleteNote(note))
    )
  }

  @Builder
  EmptyBuilder() {
    Column() {
      Image($rawfile('note_empty.svg'))
        .width(80)
        .height(80)
        .fillColor($r('app.color.text_secondary'))
        .opacity(0.5)

      Text('暂无笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })

      Text('点击右上角"新建"创建第一篇笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 13 : 15)
        .fontColor($r('app.color.text_secondary'))
        .opacity(0.7)
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  EditorCoverBuilder() {
    NoteEditor({
      note: this.editingNote,
      initialArticle: null,
      onClose: () => {
        this.showEditor = false
        this.editingNote = null
      },
      onSaved: () => {
        this.loadNotes()
      }
    })
      .expandSafeArea()
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.notes.length === 0) {
        this.EmptyBuilder()
      } else {
        List({ space: 12 }) {
          ForEach(this.notes, (note: NoteItem) => {
            ListItem() {
              this.NoteItemBuilder(note)
            }
          }, (note: NoteItem) => note.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: 16,
          right: 16,
          top: 16,
          bottom: 16
        })
      }
    }
    .padding({top:48})
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .bindContentCover(
      $$this.showEditor,
      this.EditorCoverBuilder(),
      {
        modalTransition: ModalTransition.DEFAULT
      }
    )
  }
}
