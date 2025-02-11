/* ©️ 2016 - present FlowCrypt a.s. Limitations apply. Contact human@flowcrypt.com */

'use strict';
/* eslint-disable @typescript-eslint/no-explicit-any */
export class Debug {
  private static DATA: any[] = [];

  public static readDatabase = async (): Promise<any[]> => {
    const old = Debug.DATA;
    Debug.DATA = [];
    return old; // eslint-disable-line @typescript-eslint/no-unsafe-return
  }

  public static addMessage = async (message: any): Promise<void> => {
    Debug.DATA.push(message);
  }
}
