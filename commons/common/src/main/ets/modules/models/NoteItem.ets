/**
 * 笔记数据模型
 */

/**
 * 笔记内容块类型
 */
export enum NoteContentType {
  /** 文本内容 */
  TEXT = 'text',
  /** 图片内容 */
  IMAGE = 'image'
}

/**
 * 笔记内容块
 */
export interface NoteContentBlock {
  /** 内容类型 */
  type: NoteContentType
  /** 内容值（文本或图片URI） */
  value: string
}

/**
 * 关联文章简要信息
 */
export interface LinkedArticleInfo {
  /** 文章ID */
  id: string
  /** 文章标题 */
  title: string
  /** 文章来源 */
  source?: string
  /** 文章日期 */
  date: string
  /** 文章URL */
  url: string
}

/**
 * 笔记项
 */
export interface NoteItem {
  /** 笔记唯一ID */
  id: string
  /** 笔记标题 */
  title: string
  /** 笔记内容块数组 */
  content: NoteContentBlock[]
  /** 关联文章列表（最多5篇） */
  linkedArticles: LinkedArticleInfo[]
  /** 创建时间戳 */
  createTime: number
  /** 更新时间戳 */
  updateTime: number
}

/**
 * 笔记更新触发器
 */
@ObservedV2
export class NoteUpdateTrigger {
  @Trace trigger: number = 0

  update(): void {
    this.trigger++
  }
}
