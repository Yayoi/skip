Feature: 一般ユーザが自身のプロフィール画像を管理する
  一般ユーザとしてプロフィール画像の管理を行いたい

  Background:
    Given 言語は"ja-JP"
    And 以下のテナントを作成する
      |name   |
      |skip   |
      |sg     |
    And 以下のユーザを作成する
      |name    |email           |password   |tenant_name  |admin  |
      |alice   |alice@test.com  |Password1  |skip         |true   |
      |jack    |jack@test.com   |Password1  |skip         |false  |
    And "alice@test.com"でログインする

  Scenario: プロフィール画像変更画面を初期表示する
    When "マイページ"にアクセスする
    And "自分の管理"リンクをクリックする
    And "プロフィール画像変更"リンクをクリックする

    Then "プロフィール画像は10枚までしかアップロード出来ません。画像サイズは 200 kbまでです。"と表示されていること

  Scenario: プロフィール画像の変更が許可されていない場合は、プロフィール画像変更画面へのリンクが表示されない
    Given プロフィール画像の変更を許可しないように設定する

    When "マイページ"にアクセスする
    And "自分の管理"リンクをクリックする

    Then "プロフィール画像変更"と表示されていないこと

    When "マイページ"にアクセスする

    Then "[画像を変更する]"と表示されていないこと

  Scenario: プロフィール画像を新規にアップロード/更新/削除に成功する
    Given "マイページ"にアクセスする
    And "自分の管理"リンクをクリックする
    And "プロフィール画像変更"リンクをクリックする

    When "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And "アップロード"ボタンをクリックする

    Then flashメッセージに"画像を変更しました"と表示されていること

    When "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And "アップロード"ボタンをクリックする

    Then flashメッセージに"画像を変更しました"と表示されていること

    When "削除"リンクをクリックする

    Then flashメッセージに"画像を削除しました"と表示されていること

  Scenario: プロフィール画像のサイズが大きすぎる場合はアップロードに失敗する
    Given "マイページ"にアクセスする
    And "自分の管理"リンクをクリックする
    And "プロフィール画像変更"リンクをクリックする

    When "ファイル"としてファイル"spec/fixtures/data/too_large_profile.png"をContent-Type"image/png"として添付する
    And "アップロード"ボタンをクリックする

    Then flashメッセージに"ファイルサイズが大きすぎます。"と表示されていること
