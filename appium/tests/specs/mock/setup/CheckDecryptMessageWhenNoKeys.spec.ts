import { MockApi } from 'api-mocks/mock';
import {
  KeysScreen,
  MailFolderScreen,
  SetupKeyScreen,
  SplashScreen,
} from '../../../screenobjects/all-screens';
import { ekmKeySamples } from "../../../../api-mocks/apis/ekm/ekm-endpoints";
import { CommonData } from "../../../data";
import AppiumHelper from "../../../helpers/AppiumHelper";
import BaseScreen from 'tests/screenobjects/base.screen';
import { MockApiConfig } from 'api-mocks/mock-config';

describe('SETUP: ', () => {

  it('check decrypt message when there are no keys available', async () => {

    const mockApi = new MockApi();
    const subject = 'Signed and encrypted message';

    mockApi.fesConfig = MockApiConfig.defaultEnterpriseFesConfiguration;
    mockApi.ekmConfig = MockApiConfig.defaultEnterpriseEkmConfiguration;
    mockApi.addGoogleAccount('e2e.enterprise.test@flowcrypt.com', {
      messages: [subject]
    })

    const processArgs = CommonData.mockProcessArgs;

    await mockApi.withMockedApis(async () => {
      // stage 1 - setup
      await SplashScreen.mockLogin();
      await SetupKeyScreen.setPassPhrase();
      await KeysScreen.openScreenFromSideMenu();
      await KeysScreen.checkKeysScreen([ekmKeySamples.key0, ekmKeySamples.e2e, ekmKeySamples.key1]);

      // stage 2 - erase local keys
      mockApi.ekmConfig = {
        returnKeys: []
      }
      await AppiumHelper.restartApp(processArgs);
      await MailFolderScreen.clickOnEmailBySubject(subject);
      await BaseScreen.checkModalMessage(CommonData.errors.decryptMessageWithNoKeys);
    });
  });
});
