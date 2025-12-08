/**
 * 笔记管理器
 * 负责笔记的增删改查和持久化存储
 */
import {
  APP_KV_DB,
  kvDatabase,
  KV_DB_KEYS,
  logger,
  LOG_TAG,
  APP_STORAGE_KEYS,
  NoteItem,
  NoteContentBlock,
  LinkedArticleInfo,
  NoteUpdateTrigger
} from "common"
import { distributedKVStore } from "@kit.ArkData"
import { AppStorageV2 } from "@kit.ArkUI"

/**
 * 创建笔记的输入参数
 */
export interface CreateNoteInput {
  title: string
  content: NoteContentBlock[]
  linkedArticles: LinkedArticleInfo[]
}

/**
 * 更新笔记的输入参数
 */
export interface UpdateNoteInput {
  title?: string
  content?: NoteContentBlock[]
  linkedArticles?: LinkedArticleInfo[]
}

export class NoteManager {
  private appKVDb: distributedKVStore.SingleKVStore | undefined = undefined
  private noteUpdateTrigger: NoteUpdateTrigger | undefined = undefined

  /**
   * 初始化笔记管理器
   */
  async init(): Promise<boolean> {
    try {
      const store = await kvDatabase.getKVStoreById(APP_KV_DB)
      if (store) {
        this.appKVDb = store
      }
      this.noteUpdateTrigger = AppStorageV2.connect(
        NoteUpdateTrigger,
        APP_STORAGE_KEYS.NOTE_UPDATE_TRIGGER,
        () => new NoteUpdateTrigger()
      )
      if (this.appKVDb) {
        logger.info(`${LOG_TAG.NEWS_MANAGER}NoteManager 初始化成功`)
        return true
      }
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}NoteManager 初始化失败: ${JSON.stringify(error)}`)
    }
    return false
  }


  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return `note_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`
  }

  /**
   * 获取所有笔记列表
   */
  async getNoteList(): Promise<NoteItem[]> {
    if (!this.appKVDb) {
      return []
    }

    try {
      const data = await this.appKVDb.get(KV_DB_KEYS.NOTE_LIST) as string
      const notes = JSON.parse(data) as NoteItem[]
      // 按更新时间倒序排序
      return notes.sort((a, b) => b.updateTime - a.updateTime)
    } catch (e) {
      return []
    }
  }

  /**
   * 根据ID获取笔记
   */
  async getNoteById(noteId: string): Promise<NoteItem | null> {
    const notes = await this.getNoteList()
    return notes.find(note => note.id === noteId) || null
  }

  /**
   * 创建新笔记
   */
  async createNote(input: CreateNoteInput): Promise<NoteItem | null> {
    if (!this.appKVDb) {
      return null
    }

    try {
      const notes = await this.getNoteList()
      const now = Date.now()
      const newNote: NoteItem = {
        id: this.generateId(),
        title: input.title,
        content: input.content,
        linkedArticles: input.linkedArticles.slice(0, 5),
        createTime: now,
        updateTime: now
      }

      notes.unshift(newNote)
      await this.appKVDb.put(KV_DB_KEYS.NOTE_LIST, JSON.stringify(notes))
      this.noteUpdateTrigger?.update()
      logger.info(`${LOG_TAG.NEWS_MANAGER}创建笔记成功: ${newNote.title}`)
      return newNote
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}创建笔记失败: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 更新笔记
   */
  async updateNote(noteId: string, updates: UpdateNoteInput): Promise<boolean> {
    if (!this.appKVDb) {
      return false
    }

    try {
      const notes = await this.getNoteList()
      const index = notes.findIndex(note => note.id === noteId)
      if (index === -1) {
        return false
      }

      const existing = notes[index]
      const updatedNote: NoteItem = {
        id: existing.id,
        title: updates.title !== undefined ? updates.title : existing.title,
        content: updates.content !== undefined ? updates.content : existing.content,
        linkedArticles: updates.linkedArticles !== undefined
          ? updates.linkedArticles.slice(0, 5)
          : existing.linkedArticles,
        createTime: existing.createTime,
        updateTime: Date.now()
      }

      notes[index] = updatedNote
      await this.appKVDb.put(KV_DB_KEYS.NOTE_LIST, JSON.stringify(notes))
      this.noteUpdateTrigger?.update()
      logger.info(`${LOG_TAG.NEWS_MANAGER}更新笔记成功: ${updatedNote.title}`)
      return true
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}更新笔记失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 删除笔记
   */
  async deleteNote(noteId: string): Promise<boolean> {
    if (!this.appKVDb) {
      return false
    }

    try {
      let notes = await this.getNoteList()
      const originalLength = notes.length
      notes = notes.filter(note => note.id !== noteId)

      if (notes.length === originalLength) {
        return false
      }

      await this.appKVDb.put(KV_DB_KEYS.NOTE_LIST, JSON.stringify(notes))
      this.noteUpdateTrigger?.update()
      logger.info(`${LOG_TAG.NEWS_MANAGER}删除笔记成功`)
      return true
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}删除笔记失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 保存或更新笔记（自动判断新建或更新）
   */
  async saveNote(note: NoteItem): Promise<boolean> {
    if (note.id) {
      const existing = await this.getNoteById(note.id)
      if (existing) {
        const updateInput: UpdateNoteInput = {
          title: note.title,
          content: note.content,
          linkedArticles: note.linkedArticles
        }
        return await this.updateNote(note.id, updateInput)
      }
    }
    const createInput: CreateNoteInput = {
      title: note.title,
      content: note.content,
      linkedArticles: note.linkedArticles
    }
    const created = await this.createNote(createInput)
    return created !== null
  }
}

export const noteManager = new NoteManager()
