# -*- coding: utf-8 -*-
# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
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

describe Group do
  before(:each) do
    @group = Group.new({ :name => 'hoge', :gid => 'hoge', :description => 'hoge', :protected => '1',
                         :created_on => Time.now, :updated_on => Time.now })
  end

  it { @group.should be_valid }
  it { @group.symbol_id.should == @group.gid }
  it { @group.symbol.should == ('gid:'+@group.gid) }
  it { @group.to_s.should == "id:#{@group.id}, name:#{@group.name}" }
end

describe Group, "承認待ちのユーザがいるとき" do
  before(:each) do
    @group = Group.new
    @group_participations = [GroupParticipation.new({ :waiting => true })]
    @group.should_receive(:group_participations).and_return(stub('group_participations', :find => @group_participations))
  end

  it "has_waitingはtrueを返す" do
    @group.has_waiting.should be_true
  end
end

describe Group, "承認待ちのユーザがいないとき" do
  before(:each) do
    @group = Group.new
    @group_participations = []
    @group.should_receive(:group_participations).and_return(stub('group_participations', :find => @group_participations))
  end

  it "has_waiting false " do
    @group.has_waiting.should be_false
  end
end

describe "あるグループがあるとき" do
  fixtures :users
  before(:each) do
    @group = Group.new({ :name => 'hoge', :gid => 'hoge', :description => 'hoge', :protected => '1',
                         :created_on => Time.now, :updated_on => Time.now })
    @link_group = mock_model(Group)
    @link_group.stub!(:name).and_return('foo')
    @link_group.stub!(:symbol).and_return('foo')
    Group.should_receive(:find_by_gid).twice.and_return(@link_group)
  end

  it "イベント招待メールが投稿できる" do
    lambda {
      @group.create_entry_invite_group(users(:a_user).id, 'hoge', ['uid:hoge'])
    }.should change(BoardEntry, :count).by(1)
  end
end

class GroupTest < Test::Unit::TestCase
  fixtures :users, :groups, :group_participations

  def test_participation_users
    # 管理者のみ取得できるかどうか
    owned_users = @a_protected_group1.participation_users :owned => true
    assert_equal owned_users.size, 1

    # 承認待ちユーザのみ取得できるかどうか
    joined_users = @a_protected_group1.participation_users :waiting => false
    assert_equal joined_users.size, 2

    # 承認済みユーザのみ取得できるかどうか
    waiting_users = @a_protected_group1.participation_users :waiting => true
    assert_equal waiting_users.size, 1

    # 全てのユーザを取得できるかどうか
    all_users = @a_protected_group1.participation_users
    assert_equal all_users.size, 3

    # 指定件数のみ取得できるかどうか
    limited_users = @a_protected_group1.participation_users :limit => 2
    assert_equal limited_users.size, 2

    # 指定の並び順になっているかどうか
    ordered_users = @a_protected_group1.participation_users :order => "group_participations.updated_on DESC"
    assert_equal ordered_users.first, @a_group_waiting_user
  end
end
