/**
 * 笔记列表组件
 * 显示用户的所有笔记，支持新建、阅读和编辑
 */
import {
  DEVICE_TYPES,
  NoteItem,
  NoteContentType,
  APP_STORAGE_KEYS,
  NoteUpdateTrigger,
  UserConfigViewModel
} from "common"
import { deviceInfo } from "@kit.BasicServicesKit"
import { noteManager } from '../../managers/NoteManager'
import { promptAction, AppStorageV2 } from "@kit.ArkUI"
import { NoteEditor } from './NoteEditor'

@ComponentV2
export struct NoteList {
  @Event onClose: () => void = () => {}

  @Local deviceType: DEVICE_TYPES =
    deviceInfo.deviceType === DEVICE_TYPES.PHONE ? DEVICE_TYPES.PHONE : DEVICE_TYPES.TABLET
  @Local noteUpdateTrigger: NoteUpdateTrigger =
    AppStorageV2.connect(NoteUpdateTrigger, APP_STORAGE_KEYS.NOTE_UPDATE_TRIGGER, () => new NoteUpdateTrigger())!
  @Local userConfig: UserConfigViewModel =
    AppStorageV2.connect(UserConfigViewModel, APP_STORAGE_KEYS.USER_CONFIG, () => new UserConfigViewModel())!
  @Local notes: NoteItem[] = []
  @Local isLoading: boolean = true
  @Local showEditor: boolean = false
  @Local editingNote: NoteItem | null = null
  @Local isReadOnlyMode: boolean = false
  // 可拖动浮动窗口相关状态
  @Local showDraggableEditor: boolean = false
  @Local dragOffsetX: number = 20
  @Local dragOffsetY: number = 60
  @Local dragPositionX: number = 20
  @Local dragPositionY: number = 60
  // 屏幕尺寸（用于边界限制）
  @Local screenWidth: number = 360
  @Local screenHeight: number = 780

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

  createNewNote(): void {
    this.editingNote = null
    this.isReadOnlyMode = false
    if (this.userConfig.noteEditorSheetType === 2) {
      this.showDraggableEditor = true
    } else {
      this.showEditor = true
    }
  }

  viewNote(note: NoteItem): void {
    this.editingNote = note
    this.isReadOnlyMode = true
    if (this.userConfig.noteEditorSheetType === 2) {
      this.showDraggableEditor = true
    } else {
      this.showEditor = true
    }
  }

  editNote(): void {
    this.isReadOnlyMode = false
  }

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

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now.getTime() - timestamp
    if (diff < 60000) return '刚刚'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
    if (date.getFullYear() === now.getFullYear()) {
      return `${date.getMonth() + 1}月${date.getDate()}日`
    }
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
  }

  getPreviewText(note: NoteItem): string {
    const textBlocks = note.content.filter(b => b.type === NoteContentType.TEXT)
    if (textBlocks.length > 0) return textBlocks[0].value.substring(0, 100)
    const imageCount = note.content.filter(b => b.type === NoteContentType.IMAGE).length
    if (imageCount > 0) return `[${imageCount}张图片]`
    return '暂无内容'
  }

  closeDraggableEditor(): void {
    this.showDraggableEditor = false
    this.dragOffsetX = 20
    this.dragOffsetY = 60
    this.dragPositionX = 20
    this.dragPositionY = 60
  }

  /**
   * 限制拖动位置在屏幕边界内
   */
  clampDragPosition(x: number, y: number): void {
    // 窗口尺寸（百分比转换为估算值）
    const windowWidth = this.deviceType === DEVICE_TYPES.PHONE ? this.screenWidth * 0.9 : this.screenWidth * 0.5
    const windowHeight = this.screenHeight * 0.75

    // 边界限制（留出一些边距）
    const minX = -windowWidth + 60  // 至少保留60px可见
    const maxX = this.screenWidth - 60
    const minY = 0  // 不能超出顶部
    const maxY = this.screenHeight - 100  // 底部留出100px

    this.dragOffsetX = Math.max(minX, Math.min(maxX, x))
    this.dragOffsetY = Math.max(minY, Math.min(maxY, y))
  }

  @Builder
  HeaderBuilder() {
    Row() {
      Text('我的笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 20 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()

      Button('新建')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand'))
        .height(this.deviceType === DEVICE_TYPES.PHONE ? 32 : 38)
        .borderRadius(16)
        .onClick(() => this.createNewNote())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
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
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
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
            .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 12 : 14)
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
    .margin({ bottom: 12 })
    .onClick(() => this.viewNote(note))
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.deleteNote(note)
        })
    )
  }

  @Builder
  EmptyBuilder() {
    Column() {
      Image($rawfile('note_icon.svg'))
        .width(80)
        .height(80)
        .fillColor($r('app.color.text_secondary'))
        .opacity(0.5)

      Text('暂无笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 16 : 18)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })

      Text('点击右上角"新建"按钮创建第一篇笔记')
        .fontSize(this.deviceType === DEVICE_TYPES.PHONE ? 14 : 16)
        .fontColor($r('app.color.text_secondary'))
        .opacity(0.7)
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  EditorSheetBuilder() {
    NoteEditor({
      note: this.editingNote,
      isReadOnly: this.isReadOnlyMode,
      onClose: () => {
        this.showEditor = false
      },
      onSaved: () => {
        promptAction.openToast({ message: '笔记已保存', duration: 1500 })
      },
      onEdit: () => {
        this.editNote()
      }
    })
  }

  @Builder
  DraggableEditorBuilder() {
    Column() {
      Row() {
        Row() {
          Image($rawfile('drag_handle.svg'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
          Text('拖动移动窗口')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 8 })
        }
        .layoutWeight(1)

        Image($rawfile('close.svg'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
          .onClick(() => {
            this.closeDraggableEditor()
          })
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius({ topLeft: 16, topRight: 16 })

      NoteEditor({
        note: this.editingNote,
        isReadOnly: this.isReadOnlyMode,
        onClose: () => {
          this.closeDraggableEditor()
        },
        onSaved: () => {
          promptAction.openToast({ message: '笔记已保存', duration: 1500 })
        },
        onEdit: () => {
          this.editNote()
        }
      })
    }
    .width(this.deviceType === DEVICE_TYPES.PHONE ? '90%' : '50%')
    .height('75%')
    .backgroundColor($r('app.color.page_background'))
    .borderRadius(16)
    .shadow({
      radius: 24,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 8
    })
    .clip(true)
  }

  build() {
    Stack() {
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
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.notes.length === 0) {
          this.EmptyBuilder()
        } else {
          List() {
            ForEach(this.notes, (note: NoteItem) => {
              ListItem() {
                this.NoteItemBuilder(note)
              }
            }, (note: NoteItem) => note.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))

      if (this.showDraggableEditor) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')

        Column() {
          this.DraggableEditorBuilder()
        }
        .translate({ x: this.dragOffsetX, y: this.dragOffsetY })
        .gesture(
          PanGesture()
            .onActionUpdate((event: GestureEvent | undefined) => {
              if (event) {
                const newX = this.dragPositionX + event.offsetX
                const newY = this.dragPositionY + event.offsetY
                this.clampDragPosition(newX, newY)
              }
            })
            .onActionEnd(() => {
              this.dragPositionX = this.dragOffsetX
              this.dragPositionY = this.dragOffsetY
            })
        )
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.screenWidth = newValue.width as number
      this.screenHeight = newValue.height as number
    })
    .bindSheet(
      this.showEditor,
      this.EditorSheetBuilder(),
      {
        height: '100%',
        width: this.deviceType === DEVICE_TYPES.PHONE ? '95%' : '50%',
        dragBar: false,
        showClose: false,
        backgroundColor: $r('app.color.page_background'),
        preferType: this.userConfig.noteEditorSheetType as SheetType,
        onDisappear: () => {
          this.showEditor = false
        }
      }
    )
  }
}
