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

import { curves } from "@kit.ArkUI";
import { NAV_DESTS, KV_DB_KEYS, PreferenceEnum, DEVICE_TYPES } from './enums';

export const NAV_PATH_STUCK = 'navPathStuck'

export const NEWS_LIST_ITEM_ANIMATE_PARAM = TransitionEffect.OPACITY
  .combine(TransitionEffect.scale({ x: 0.5, y: 0.5 }))
  .animation({ curve: curves.springMotion(0.5, 0.7) })
;

export { NAV_DESTS, KV_DB_KEYS, PreferenceEnum, DEVICE_TYPES }

// export const SERVE_BASE_ADDRESS = 'http://localhost:8001'
// export const SERVE_BASE_ADDRESS = 'http://192.168.1.4:8001'
export const SERVE_BASE_ADDRESS = 'http://113.47.8.204:32776'

// export const SERVE_BASE_ADDRESS = 'http://192.168.43.6:8001'
export const GET_USER_CONFIG = 'UserConfig'

export const WINDOW_WIDTH = 'Window width'

export const DEFAULT_FONT_SIZE = 16

export const DEFAULT_COLOR_MODE = 2

export const APP_KV_DB = 'NowInOpenHarmonyKVDB'

export const GET_BREAK_POINT_SYSTEM = 'getBreakpointSystem'

export const IS_STICKY = 'isSticky'

export const NEWS_LIST_ANIMATION_PARAM: AnimateParam = {
  curve: Curve.EaseInOut,
  duration: 200,
}