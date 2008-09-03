# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__) + '/../spec_helper'

describe BoardEntry, "に何も値が設定されていない場合" do
  before(:each) do
    @board_entry = BoardEntry.new
  end
  it { @board_entry.should_not be_valid }
  it { @board_entry.should have(1).errors_on(:title) }
  it { @board_entry.should have(1).errors_on(:contents) }
  it { @board_entry.should have(1).errors_on(:date) }
  it { @board_entry.should have(1).errors_on(:user_id) }
end

describe BoardEntry, "に正しい値が設定されている場合" do
  before(:each) do
    @board_entry = BoardEntry.new({ :title => "hoge", :contents => "hoge",
                                    :date => Date.today, :user_id => 1,
    # FIXME この行からvalidateがかかっていないのに保存しようとするとMysqlエラー
                                    :last_updated => Date.today })
  end

  it { @board_entry.should be_valid }
  it "正しく保存される" do
    lambda { @board_entry.save! }.should_not raise_error
  end
  it "保存するときにBoardEntryPointが作成される" do
    BoardEntryPoint.should_receive(:create)
    @board_entry.save!
  end

  describe BoardEntry, "にタグが設定されている場合" do
    before(:each) do
      @board_entry.category = 'foo,bar'
    end

    it "保存する際にTagが保存される" do
      Tag.should_receive(:create_by_string)
      @board_entry.save
    end
  end
end

describe BoardEntry, "があるユーザの日記だったとき" do
  fixtures :board_entries
  before(:each) do
    @board_entry = board_entries(:a_entry)
  end

  it { @board_entry.permalink.should == "/page/#{@board_entry.id}" }
  it { @board_entry.important?.should be_false }
  it { @board_entry.public?.should be_true}
  it { @board_entry.private?.should be_false }
  it { @board_entry.protected?.should be_false  }
  # TODO: このメソッドはいらない気がする。過去の消し忘れか
  #  it { @board_entry.owner_is_public?.should be_true }
  # TODO: BoardEntry#get_around_entryのテスト
  #      select文の + の意味が分からん
  #      文字列連結をしているようだ
  #      周りのエントリを探すだけなのになぜここまでの処理が必要か？
end

# TODO: BoardEntry.make_conditionsのテスト
# TODO: BoardEntry.find_visibleのテスト

describe "BoardEntry.get_category_words 複数のタグが見つかったとき" do
  before(:each) do
    @board_entry = mock_model(BoardEntry)
    @board_entry.stub!(:id).and_return(1)
    BoardEntry.should_receive(:find).and_return([@board_entry])
    @tag1 = mock_model(Tag)
    @tag2 = mock_model(Tag)
    @tag3 = mock_model(Tag)
    @tag1.stub!(:name).and_return('z')
    @tag2.stub!(:name).and_return('a')
    @tag3.stub!(:name).and_return('z')
    Tag.should_receive(:find).and_return([@tag1,@tag2,@tag3])
  end

  it "タグの名前をユニークにして並べ替えて返す" do
    BoardEntry.get_category_words.should == ['a','z']
  end
end

describe "BoardEntry.get_popular_tag_words で複数タグが見つかったとき" do
  before(:each) do
    @tag1 = mock_model(EntryTag)
    @tag1.stub!(:name).and_return('z')
    @tag2 = mock_model(EntryTag)
    @tag2.stub!(:name).and_return('a')
    @tag3 = mock_model(EntryTag)
    @tag3.stub!(:name).and_return('z')
    EntryTag.should_receive(:find).and_return([@tag1,@tag2,@tag3])
  end
  it "タグの名前をユニークして返す" do
    BoardEntry.get_popular_tag_words.should == ['z','a']
  end
end

describe BoardEntry do
  fixtures :board_entries, :groups, :users, :mails, :tags, :user_uids, :user_profiles

  def test_validate_category
    # カテゴリに+,/,-,_,.以外の記号を含む場合 => validationにひっかかる
    # その他タグ周りの細かいvalidateについてはTagのテストで実施している
    @a_entry.category = "[あ=あ][*いえ]"
    assert !@a_entry.valid?
  end

  def test_after_save
    @a_entry.category = ''
    @a_entry.save
    assert_equal @a_entry.entry_tags.size, 0

    @a_entry.category = SkipFaker.comma_tags :qt => 2
    @a_entry.save
    assert_equal @a_entry.entry_tags.size, 2
  end

# FIXME テストを汎用化する
  def test_publication_users
    entry = BoardEntry.new(store_entry_params({ :user_id => @a_user.id,
                                                :last_updated => Time.now,
                                                :symbol => "uid:#{@a_user.uid}"}))

    # 単一ユーザに対する公開
    entry.entry_publications.build(:symbol => "uid:#{@a_group_owned_user.uid}")
    users = entry.publication_users.map{ |user| user.id }
    assert_equal 1, users.size
    assert_equal @a_group_owned_user.id, users.first

    # 複数ユーザに対する公開
    entry.entry_publications.build(:symbol => "uid:#{@a_group_joined_user.uid}")
    users = entry.publication_users.map{ |user| user.id }
    assert_equal 2, users.size
    assert users.include?(@a_group_owned_user.id)
    assert users.include?(@a_group_joined_user.id)
  end

  def test_prepare_send_mail
    # 直接指定のエントリ
    entry = BoardEntry.new(store_entry_params({ :user_id => @a_user.id,
                                                :last_updated => Time.now,
                                                :symbol => "uid:#{@a_user.uid}",
                                                :category => "[#{Tag::NOTICE_TAG}]",
                                                :publication_type => 'private'}))

    Mail.delete_all
    # 単一ユーザに対する連絡
    entry.entry_publications.build(:symbol => "uid:#{@a_group_owned_user.uid}")
    entry.prepare_send_mail
    mails = Mail.find(:all)
    assert_equal 1, mails.size
    assert_equal @a_group_owned_user.user_profile.email, mails.first.to_address

    Mail.delete_all
    # 複数ユーザに対する連絡
    entry.entry_publications.build(:symbol => "uid:#{@a_group_joined_user.uid}")
    entry.prepare_send_mail
    mails, mail_address = get_mails

    assert_equal 2, mails.size
    assert_not_nil mail_address.index(@a_group_owned_user.user_profile.email)
    assert_not_nil mail_address.index(@a_group_joined_user.user_profile.email)
    Mail.delete_all

  end

  def test_make_conditions
    # login_user_symbolsの値によらず公開条件が設定されている
    public_state = "(entry_publications.symbol in (?))"
    assert BoardEntry.make_conditions([])[:conditions].include?(public_state)
    assert BoardEntry.make_conditions(["uid:maeda"])[:conditions].include?(public_state)

    # 種別
    entry_type_state = " and board_entries.entry_type='DIARY'"
    assert BoardEntry.make_conditions([], {:entry_type => 'DIARY'})[:conditions].include?(public_state + entry_type_state)

    # 除外種別
    exclude_entry_type_state = " and board_entries.entry_type<>'EVENT'"
    assert BoardEntry.make_conditions([], {:exclude_entry_type => 'EVENT'})[:conditions].include?(public_state + exclude_entry_type_state)

    # 公開範囲
    publication_type_state = " and board_entries.publication_type='public'"
    assert BoardEntry.make_conditions([], {:publication_type => 'public'})[:conditions].include?(public_state + publication_type_state)

    # 所有者条件
    symbols_state = " and board_entries.symbol in (?) "
    # nilや空配列の場合は条件に追加されない。
    assert BoardEntry.make_conditions([], {:symbols => nil})[:conditions].include?(public_state)
    assert BoardEntry.make_conditions([], {:symbols => []})[:conditions].include?(public_state)
    assert BoardEntry.make_conditions([], {:symbols => ['uid:maeda']})[:conditions].include?(public_state + symbols_state)

    # 書いた人
    writer_id_state = " and board_entries.user_id = ? "
    assert BoardEntry.make_conditions([], {:writer_id => ['1']})[:conditions].include?(public_state + writer_id_state)

    # キーワード検索
    keyword_state = " and (board_entries.title like ? or board_entries.contents like ? or board_entries.category like ?)"
    assert BoardEntry.make_conditions([], {:keyword => ''})[:conditions].include?(public_state)
    assert BoardEntry.make_conditions([], {:keyword => 'hoge'})[:conditions].include?(public_state + keyword_state)

    # id条件(一意)
    id_state = " and board_entries.id = ?"
    assert BoardEntry.make_conditions([], {:id => '1'})[:conditions].include?(public_state + id_state)

    # id条件(複数)
    ids_state = " and board_entries.id in (?)"
    assert BoardEntry.make_conditions([], {:ids => [1,2,3]})[:conditions].include?(public_state + ids_state)

    # カテゴリ(単独)
    category_state = " and board_entries.category like ?"
    # カテゴリが空の場合は条件に追加されない
    assert BoardEntry.make_conditions([], {:category => ''})[:conditions].include?(public_state)
    assert BoardEntry.make_conditions([], {:category => '[hoge]'})[:conditions].include?(public_state + category_state)

    # カテゴリ(複数)
    # カテゴリが空配列の場合は条件に追加されない
    assert BoardEntry.make_conditions([], {:categories => []})[:conditions].include?(public_state)
    assert BoardEntry.make_conditions([], {:categories => ['[hoge]','[fuga]']})[:conditions].include?(public_state + category_state * 2)

    # タグ
    # FIXME テスト対象のソースもっと綺麗に出来そう。カテゴリと合わせてもっとシンプルにしたい。
    and_tag_words_state = " and board_entries.category like ?"
    or_start_words_state = " and ("
    or_tag_words_state = " board_entries.category like ? OR"
    or_end_tag_words_state = " board_entries.category like ?)"
    # tag_wordsのみ指定だと条件に追加されない
    assert BoardEntry.make_conditions([], {:tag_words => 'hoge'})[:conditions].include?(public_state)
    # tag_selectのみ指定だと条件に追加されない
    assert BoardEntry.make_conditions([], {:tag_select => 'AND'})[:conditions].include?(public_state)
    # タグ1つ, AND
    assert BoardEntry.make_conditions([], {:tag_words => 'hoge,fuga', :tag_select => 'AND'})[:conditions].include?(public_state + and_tag_words_state * 2)
    # タグ複数, AND
    assert BoardEntry.make_conditions([], {:tag_words => 'hoge', :tag_select => 'AND'})[:conditions].include?(public_state + and_tag_words_state)
    # タグ1つ, OR
    assert BoardEntry.make_conditions([], {:tag_words => 'hoge', :tag_select => 'OR'})[:conditions].include?(public_state + or_start_words_state + or_end_tag_words_state)
    # タグ複数, OR
    assert BoardEntry.make_conditions([], {:tag_words => 'hoge,fuga', :tag_select => 'OR'})[:conditions].include?(public_state + or_start_words_state + or_tag_words_state + or_end_tag_words_state)

    # 最近の何日間条件
    recent_day_state = " and last_updated >  ?"
    assert BoardEntry.make_conditions([], {:recent_day => Date.new(2008, 1, 10)})[:conditions].include?(public_state + recent_day_state)

  end

private

  def get_mails
    mails = Mail.find(:all)
    mail_address = ""
    mails.each { |mail| mail_address += mail.to_address + "," }
    return mails, mail_address
  end

  def store_entry_params params={}
    entry_template = {
      :title => "test",
      :contents => "test",
      :date => Date.today,
      :category => "",
      :entry_type => "BBS",
      :ignore_times => false,
      :user_entry_no => 1,
      :editor_mode => "hiki",
      :lock_version => 0,
      :publication_type => "public",
      :entry_trackbacks_count => 0,
      :board_entry_comments_count => 0
    } # user_id, last_updated, symbolが未設定

    params.each do |key, value|
      entry_template.store(key, value)
    end
    return entry_template
  end
end
