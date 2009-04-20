Feature: ランキング
  月次と総合での記事ごとのアクセス数などのランキングを表示できる。データの収集は、バッチで行う。

  Scenario: アクセス数ランキングを集計して、表示する
    Given   言語は"ja-JP"
    And     現在時刻の定義を一旦退避する
    And     現在時刻を2009-01-01とする
    When    "a_user"でブログを書く
    And     ログアウトする
    And     "a_group_owned_user"で"1"つめのブログにアクセスする
    And     "2"回再読み込みする
    And     ランキングのバッチで"2009-01-01"分を実行する

    Then     "entry_access"ランキングの"2009-01"分を表示する
    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"3"であること

    Then    "entry_access"ランキングの総合を表示する
    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"3"であること

    Given   現在時刻を2009-01-02とする

    And     ログアウトする
    When    "a_group_owned_user"でブログを書く
    And     ログアウトする
    And     "a_group_owned_user"で"1"つめのブログにアクセスする
    And     "2"回再読み込みする
    And     ログアウトする
    And     "a_user"で"2"つめのブログにアクセスする
    And     "4"回再読み込みする
    And     ランキングのバッチで"2009-01-02"分を実行する

    Then    "entry_access"ランキングの"2009-01"分を表示する
    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"6"であること
    And     ランキングの"2"位が"2"つめのブログであること
    And     ランキングの"2"位の数が"5"であること

    Then    "entry_access"ランキングの総合を表示する
    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"6"であること
    And     ランキングの"2"位が"2"つめのブログであること
    And     ランキングの"2"位の数が"5"であること

    Given   現在時刻を2009-02-01とする

    And     ログアウトする
    When    "a_user"でブログを書く
    And     ログアウトする
    And     "a_group_owned_user"で"1"つめのブログにアクセスする
    And     "2"回再読み込みする
    And     ログアウトする
    And     "a_group_owned_user"で"3"つめのブログにアクセスする
    And     "4"回再読み込みする
    And     ランキングのバッチで"2009-02-01"分を実行する

    Then    "entry_access"ランキングの"2009-02"分を表示する
    And     ランキングの"1"位が"3"つめのブログであること
    And     ランキングの"1"位の数が"5"であること
    And     ランキングの"2"位が"1"つめのブログであること
    And     ランキングの"2"位の数が"3"であること

    Then    "entry_access"ランキングの総合を表示する

    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"9"であること
    And     ランキングの"2"位が"2"つめのブログであること
    And     ランキングの"2"位の数が"5"であること
    And     ランキングの"3"位が"3"つめのブログであること
    And     ランキングの"3"位の数が"5"であること

    Given   現在時刻を2009-03-01とする

    And     ログアウトする
    When    "a_user"でブログを書く
    And     ログアウトする
    And     "a_group_owned_user"で"1"つめのブログにアクセスする
    And     "2"回再読み込みする
    And     ログアウトする
    And     "a_group_owned_user"で"4"つめのブログにアクセスする
    And     "4"回再読み込みする
    And     ランキングのバッチで"2009-03-01"分を実行する

    Then    "entry_access"ランキングの"2009-03"分を表示する
    And     ランキングの"1"位が"4"つめのブログであること
    And     ランキングの"1"位の数が"5"であること
    And     ランキングの"2"位が"1"つめのブログであること
    And     ランキングの"2"位の数が"3"であること

    Then    "entry_access"ランキングの総合を表示する
    And     ランキングの"1"位が"1"つめのブログであること
    And     ランキングの"1"位の数が"12"であること
    And     ランキングの"2"位が"2"つめのブログであること
    And     ランキングの"2"位の数が"5"であること
    And     ランキングの"3"位が"3"つめのブログであること
    And     ランキングの"3"位の数が"5"であること
    And     ランキングの"4"位が"4"つめのブログであること
    And     ランキングの"4"位の数が"5"であること

    And     現在時刻を元に戻す

