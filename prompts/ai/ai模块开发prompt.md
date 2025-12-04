# ai对话模块开发

## 项目简介

我当前的项目是一个鸿蒙新闻与智能体问答的综合体应用，当前新闻模块的功能基本完善，需要继续开发智能体问答部分的功能，我们的智能体是开发在扣子平台上的，总共有两种模式的智能体，一种是快速回答模式，另一种是深度搜索模式。你需要帮我仿照现有的数据链路模式去进行智能体模块的开发。

## 核心需求

首先我为这个功能模块单独设置了两个功能模块ai_common和ai_feature，你需要仿照当下 common , feature , default这三者的逻辑关系去进行架构设计。common模块负责存放基础接口工具如网络请求工具，数据模型接口，数据模型类，日志工具等内容，为feature提供底层支持，随后feature层封装manager模块用于管理整体聊天流程，同时封装诸如聊天输入框，对话历史渲染列表等等功能组件，最上层的product则是最后展现给用户的UI界面层级。

### 接口封装

我给你的prompts/htmls文档文件夹包含coze空间的对话流文档，我们切换快速回答和深度思考的关键参数在于`workflow_id`，所以我们需要准备两套接口，来去拉起不同智能体的会话。利用一个AppStorageV2全局变量来设置，这个全局变量要在common中设置一个新的枚举类，利用这个枚举类去进行选择，这个枚举类有三种状态一种是未选择，一种是快速回答一种是深度思考。

我们的coze接口要使用的是流式传输，使用鸿蒙中的rcp远场通信能力来去进行流式数据的处理。这一部分的文档我也放在了prompts/htmls文件夹下。下面的代码是此前我链接coze平台并使用流式传输接口进行数据处理的代码，仅供参考，由于版本老旧一切按prompts/htmls文件夹中的文档来进行编写。

```arkts
import {
  HistoryMessages_Role,
  ICoZePostBody,
  CozeHistoryMessagesItem,
  IHXYConversationMessage_DeltaData,
  ViewMessageModel,
  HistoryMessageList,
} from "../../modules";
import { AppStorageV2, promptAction } from "@kit.ArkUI";
import { rcp } from "@kit.RemoteCommunicationKit";
import { util } from "@kit.ArkTS";
import { BusinessError } from "@kit.BasicServicesKit";
import { logger } from 'common'
import { MESSAGE_LIST, MSG, CONTENT_TYPE_STRING, STRING_BUFFER_ZONE } from '../../constants/index'
import { typeStringBuffer } from "../../utils";


/**
 * 当前正在进行接收的信息对象
 */
const currentMsg: ViewMessageModel = AppStorageV2.connect(ViewMessageModel, MSG, () => new ViewMessageModel())!;
/**
 * 当前需要发送给AI的聊天记录
 */
const historyMessageList: HistoryMessageList =
  AppStorageV2.connect(HistoryMessageList, MESSAGE_LIST, () => new HistoryMessageList())!

const ON_DATA_RECEIVE = 'onDataReceive:  ';
const sessionConfig: rcp.SessionConfiguration = {
  headers: {
    Authorization: "Bearer pat_OjbCtDedMN0L9BItNljPmHu8uuxsSZiLxHoahXpMlJtGRzuilLKfbjLBa77iqcjs",
    "Content-Type": "application/json"
  },
  requestConfiguration: {
    transfer: {
      timeout: {
        transferMs: 1200000
      }
    },
    tracing: {
      httpEventsHandler: {
        onDataReceive: (inComingData: ArrayBuffer) => {
          currentMsg.hasEnd = false
          const bufferFrom: Uint8Array = new Uint8Array(inComingData);
          const s = new util.TextDecoder().decodeToString(bufferFrom);
          logger.info('onDataReceive原始数据：  ' + s)
          const lines:string[] = s.split('\n');
          let deltaDataLines:number[]=[]
          typeStringBuffer.rcpEnd = false
          try {
            lines.forEach((item:string,index:number)=>{
              if (item.includes('conversation.message.delta')) {
                deltaDataLines.push(index+1)
              }
            })
            lines.forEach((item:string,index:number)=>{
              if (deltaDataLines.includes(index)) {
                const data = item.split('data: ')[1]
                const message_data = (JSON.parse(data) as IHXYConversationMessage_DeltaData).content.replace('null', '')
                logger.info('________________________________________________________')
                logger.info('onDataReceive data='+data)
                typeStringBuffer.strAdd(message_data)
                typeStringBuffer.start()
                logger.info('onDataReceive 向字符缓冲区写入： ' + message_data)
                logger.info('________________________________________________________')
              }
            })
          } catch (err) {
            logger.error(ON_DATA_RECEIVE + 'onDataReceive捕获异常: ' + err)
          }

        }
      }
    }
  }
}
const date = `${Date.now()}${Math.floor(Math.random() * 1000)}`

export function requestCozeAi() {
  const ai: ICoZePostBody = {
    workflow_id: '7487986803871760399',
    additional_messages: historyMessageList.getList(),
    parameters: new Map<string, string>([['CONVERSATION_NAME', 'HXY' + date]]),
    conversation_id: 'abc'+date
  }
  promptAction.showToast({
    message: '发送请求成功'
  })
  console.log('进入requestAi')
  const session = rcp.createSession(sessionConfig)
  session.post('https://api.coze.cn/v1/workflows/chat', ai)
    .catch((err: BusinessError) => {
      logger.error(err.message)
    })
    .finally(() => {
      typeStringBuffer.rcpEnd = true
      logger.warn('requestCozeAi:  ' + '当前对话流式传输结束，开始进行对话历史写入')
      const message = new CozeHistoryMessagesItem(HistoryMessages_Role.Assistant)
      message.content_type = CONTENT_TYPE_STRING
      message.content = currentMsg.content!
      historyMessageList.addMessage(message)
      logger.warn('requestCozeAi:  ' + '历史添加完毕')
      session.close()
      logger.warn('requestCozeAi:  ' + 'session已关闭')
    })
}
```

```arkts
import { logger } from 'common'
import { ViewMessageModel } from '../../modules';
import { AppStorageV2 } from '@kit.ArkUI';
import { MSG } from '../../constants';

@ObservedV2
  /**
   * 打字机效果的数据接收缓冲区
   */
class TypeStringBuffer {
  /**
   * 启动标识符
   */
  private startSign: boolean = false
  /**
   * 待输出字符串数组
   */
  private charArray: string[] = []
  /**
   * 当前轮次流式传输结束标识符
   */
  public rcpEnd: boolean = true
  currentMsg: ViewMessageModel = AppStorageV2.connect(ViewMessageModel, MSG, () => new ViewMessageModel())!;

  strAdd(addStr: string) {
    if (addStr === '') {
      logger.warn('StringBuffer.strAdd:  ' + 'str为空')
      return
    }
    logger.warn('StringBuffer.strAdd:  ' + 'addstr=' + addStr)
    for (let i = 0; i < addStr.length; i++) {
      this.charArray.push(addStr.charAt(i));
    }
    // logger.warn('StringBuffer.strAdd:  ' + 'charArray=' + this.charArray.join(''));
  }

  start() {
    if (this.startSign) {
      logger.warn('StringBuffer.start:  ' + '已经在执行')
    } else {
      this.startSign = true;
      setTimeout(() => {
        const id = setInterval(() => {
          if (this.charArray.length > 0) {
            const currentChar = this.charArray.shift()!; // 取出并删除第一个字符
            logger.warn('StringBuffer.start:  ' + 'currentChar=' + currentChar)
            this.currentMsg.content += currentChar;
          } else if (this.charArray.length === 0 && !this.rcpEnd) { // 当当前输出速度过快，本轮流式传输没有完成但缓冲区已经输出完成
            logger.warn('StringBuffer.start:  ' + '当前无数据但流失传输未结束')
          } else if (this.rcpEnd && this.charArray.length === 0) { // 当本轮流式传输结束并且缓冲区全部输出完成
            clearInterval(id);
            this.startSign = false;
            logger.warn('StringBuffer.start:  ' + '所有字符已输出');
            this.currentMsg.hasEnd = true
          }
        }, 6);
      }, 2000);
    }
  }
}
export const typeStringBuffer: TypeStringBuffer = new TypeStringBuffer()
```

```arkts
export interface ICoZePostBody<K = string, V = string> {
  /**
   * 待执行的对话流 ID，此对话流应已发布。
   */
  workflow_id: string
  /**
   * 对话中用户问题和历史消息。数组长度限制为 50，即最多传入 50 条消息。
   * 你需要通过此字段传入本次对话中用户的问题，也就是对话流的输入参数 USER_INPUT 的值。
   * 可以同时传入多条历史消息，也就是本次对话的上下文。多条消息应按对话顺序排列，最后一条消息应为 role=user 的记录，也就是**本次对话**中用户的问题；其他消息为历史消息。
   */
  additional_messages: CozeHistoryMessagesItem[]
  /**
   * 设置对话流的输入参数。
   * 对话流的输入参数  USER_INPUT 应在 additional_messages 中传入，在 parameters 中的 USER_INPUT 不生效。
   * 如果 parameters 中未指定 CONVERSATION_NAME 或其他输入参数，则使用参数默认值运行对话流；如果指定了这些参数，则使用指定值。
   */
  parameters: Map<K, V>
  // parameters:object
  /**
   * 需要关联的扣子应用 ID。调用对话流时，必须指定 app_id 或 bot_id，便于模型调用智能体或应用的数据库、变量等数据处理问题。
   */
  app_id?: string
  /**
   * 需要关联的智能体 ID。 调用对话流时，必须指定 app_id 或 bot_id，便于模型调用智能体或应用的数据库、变量等数据处理问题。
   */
  bot_id?: string
  /**
   * 对话流对应的会话 ID，对话流产生的消息会保存到此对话中。会话默认为开始节点设置的 CONVERSATION_NAME，也可以通过 conversation_id 参数指定会话。
   */
  conversation_id?: string
  /**
   * 用于指定一些额外的字段，以 Map[String][String] 格式传入。例如某些插件会隐式用到的经纬度等字段。
   目前仅支持以下字段：
   latitude：String 类型，表示经度。
   longitude：String 类型，表示纬度。
   user_id：String 类型，表示用户 ID。
   */
  ext?: Map<CoZePostBody_ExtKeys, string>
}

/**
 * 扣子流式接口Body部分字段map的键值枚举类型
 */
export enum CoZePostBody_ExtKeys {
  /**
   * latitude：String 类型，表示经度。
   */
  Latitude = 'latitude',
  /**
   * longitude：String 类型，表示纬度。
   */
  Longitude = 'longitude',
  /**
   * user_id：String 类型，表示用户 ID。
   */
  User_id = 'user_id'
}

/**
 * 对话中用户问题和历史消息。
 * 指定 content 时，应同时设置 content_type。
 * 暂不支持多模态（文本、图片、文件混合输入）、卡片等类型的内容。
 * 设置meta_data时应当设置两个泛型参数
 */
export class CozeHistoryMessagesItem<K = undefined, V = undefined> {
  /**
   * 发送这条消息的实体。
   */
  role: HistoryMessages_Role
  /**
   * 消息类型。默认为 question。
   */
  type?: HistoryMessages_Type
  /**
   * 消息的内容，仅支持纯文本。
   */
  content?: string
  /**
   * 消息内容的类型。
   */
  content_type?: string
  /**
   * 创建消息时的附加消息，获取消息时也会返回此附加消息。
   * 自定义键值对，应指定为 Map 对象格式。长度为 16 对键值对，其中键（key）的长度范围为 1～64 个字符，值（value）的长度范围为 1～512 个字符。
   */
  meta_data?: Map<K, V>

  constructor(role: HistoryMessages_Role) {
    this.role = role
  }

  public clone(): CozeHistoryMessagesItem<K, V> {
    const newItem = new CozeHistoryMessagesItem<K, V>(this.role);

    if (this.type !== undefined) {
      newItem.type = this.type;
    }

    if (this.content !== undefined) {
      newItem.content = this.content;
    }

    if (this.content_type !== undefined) {
      newItem.content_type = this.content_type;
    }

    if (this.meta_data !== undefined) {
      newItem.meta_data = new Map(this.meta_data.entries());
    }

    return newItem;
  }
}

/**
 * user：代表该条消息内容是用户发送的。
 * assistant：代表该条消息内容是模型发送的。
 */
export enum HistoryMessages_Role {
  User = 'user',
  Assistant = 'assistant'
}

/**
 * question：用户输入内容。
 * answer：模型返回给用户的消息内容，支持增量返回。如果对话流绑定了消息节点，可能会存在多 answer 场景，此时可以用流式返回的结束标志来判断所有 answer 完成。
 * function_call：智能体对话过程中调用函数（function call）的中间结果。
 * tool_response：调用工具 （function call）后返回的结果。
 */
export enum HistoryMessages_Type {
  Question = 'question',
  Answer = 'answer',
  Function_call = 'function_call',
  Tool_response = 'tool_response'
}

/**
 * 对话渲染数据模型
 */
@ObservedV2
export class ViewMessageModel {
  /**
   * 人类是1Ai是0
   */
  type: number | null = null;
  @Trace hasEnd: boolean = true;
  @Trace content: string = '';
  @Trace currentIndex?: number;
}

export interface IHXYConversationMessage_DeltaData {
  "id": string;
  "conversation_id": string;
  "role": string;
  "type": string;
  "content": string;
  "content_type": string;
  "chat_id": string;
  "section_id": string;
}

// export interface IHXYConversationMessage_Event {
//   event: string;
//   data: IHXYConversationMessage_DeltaData;
// }
```

### 新建对话与模型选择

在用户点击product/default/src/main/ets/pages/nav_pages/MainPage.ets中的ai问答子页面后product/default/src/main/ets/pages/tab_contents/AITabContent.ets组件会被拉起，在页面正中间先显示一个模式选择器，下方显示问题的输入栏。

输入框在当前文本内容长度不符合规定时不能显示发送按钮，在用户开始输入之后发送按钮从屏幕外飞入屏幕内，要有曲线速度动画，点击发送后清空输入框。在第一次点击发送后就隐藏模型选择组件，随后在模型选择的位置替代出现的是聊天历史组件。如果是深度思考的模型就要有合理的文字和动效提示用户当前的回答生成过程会很长，请耐心等待。

然后在product/default/src/main/ets/pages/tab_contents/AITabContent.ets这个页面的右上角还要有两个按钮，一个是开启新对话，一个是对话历史记录。每次启动应用并且点开AI聊天页面的时候都要新开一个会话，每个会话要有一个唯一ID，coze平台会依据conversation_id来记录历史记录，当然，我们本地也需要用KVDB键值数据对，以ID为键，记录对话的历史记录，以便于用户可以正确的留存历史记录。

如果用户拉起了AI对话页面出发了新建会话ID或是点击新建会话按钮触发了新建会话，当前ID没有实质性的聊天内容，那也不要记录这个ID。

当前并没有确定切换快速回答和深度思考的关键参数`workflow_id`，先留出两个空的枚举值以便于后续填写。

### 对话历史记录

对话历史记录要记录唯一的ID同时还要记录所选的模型类型，以便于接续对话。