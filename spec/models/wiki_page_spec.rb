#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WikiPage do
  let(:project) { FactoryGirl.create(:project).reload } # a wiki is created for project, but the object doesn't know of it (FIXME?)
  let(:wiki) { project.wiki }
  let(:wiki_page) { FactoryGirl.create(:wiki_page, :wiki => wiki) }

  describe '#nearest_parent_menu_item' do
    let!(:wiki_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => wiki_page.title) }
    let(:child_page) { FactoryGirl.create(:wiki_page, :parent => wiki_page, :wiki => wiki) }
    let!(:child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => child_page.title, :parent => wiki_page_wiki_menu_item) }
    let(:grand_child_page) { FactoryGirl.create(:wiki_page, :parent => child_page, :wiki => wiki) }
    let!(:grand_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => grand_child_page.title) }

    context 'when called without options' do
      it 'returns the menu item of the parent page' do
        grand_child_page.nearest_parent_menu_item.should == child_page_wiki_menu_item
      end
    end

    context 'when called with {is_main_item => true}' do
      it 'returns the menu item of the grand parent if the menu item of its parent is not a main item' do
        grand_child_page.nearest_parent_menu_item(is_main_item: true).should == wiki_page_wiki_menu_item
      end
    end
  end

  describe '#destroy' do
    context 'when the only wiki page is destroyed' do
      before do
        wiki_page.destroy
        project.reload
      end

      it 'deactivates the wiki module' do
        project.module_enabled?(:wiki).should be_false
      end

      it 'destroys the project wiki' do
        project.wiki.should be_nil
      end
    end

    context 'when one of two wiki pages is destroyed' do
      before do
        another_wiki_page = FactoryGirl.create(:wiki_page, :wiki => wiki)
        wiki_page.destroy
        project.reload
      end

      it 'does not deactivate the wiki module' do
        project.module_enabled?(:wiki).should be_true
      end

      it 'does not destroy the project wiki' do
        project.wiki.should be_present
      end
    end
  end
end
