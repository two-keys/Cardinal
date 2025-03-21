# frozen_string_literal: true

class ThemesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include Pagy::Backend
  include ApplicationHelper

  before_action :authenticate_user!
  before_action :set_theme, only: %i[show edit update destroy apply unapply]

  authorize_resource

  # GET /themes or /themes.json
  def index
    @pagy, @themes = pagy(Theme.available(current_user))
  end

  # GET /themes/1 or /themes/1.json
  def show; end

  # GET /themes/new
  def new
    @theme = Theme.new
    @theme.css = default_content
  end

  # GET /themes/1/edit
  def edit; end

  # POST /themes or /themes.json
  def create
    params = theme_params

    params.except(:public, :system) unless admin?

    @theme = Theme.new(theme_params)
    @theme.user = current_user

    respond_to do |format|
      if @theme.save
        format.html { redirect_to @theme, notice: 'Theme was successfully created.' }
        format.json { render :show, status: :created, location: @theme }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /themes/1 or /themes/1.json
  def update
    params = theme_params

    params = params.except(:public, :system) unless admin?

    respond_to do |format|
      if @theme.update(params)
        format.html { redirect_to edit_theme_path(@theme), notice: 'Theme was successfully updated.' }
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /themes/1 or /themes/1.json
  def destroy
    @theme.destroy!

    respond_to do |format|
      format.html { redirect_to themes_path, status: :see_other, notice: 'Theme was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /themes/1/apply or /themes/1/apply.json
  def apply
    if @theme.system? && @theme.entitlement && current_user.entitlements.exclude?(@theme.entitlement)
      current_user.entitlements << @theme.entitlement
    end
    respond_to do |format|
      if current_user.applied_themes << @theme
        format.html do
          redirect_back fallback_location: themes_url, notice: 'Theme was successfully applied.'
        end
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html do
          redirect_back fallback_location: themes_url, status: :unprocessable_entity
        end
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /themes/1/unapply or /themes/1/unapply.json
  def unapply
    respond_to do |format|
      if current_user.user_themes.where(theme_id: @theme.id).destroy_all
        format.html do
          redirect_back fallback_location: themes_url, notice: 'Theme was successfully unapplied.'
        end
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html do
          redirect_back fallback_location: themes_url, status: :unprocessable_entity
        end
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def default_content
    <<~CSS
      [data-theme='light'] {
        --color-primary: #d6d6d6;
        --color-primary-content: rgb(44, 44, 44);
        --color-header: #9c9c9c;
        --color-header-content: #5c5959;
        --color-secondary: #bebebe;
        --color-secondary-content: rgb(61, 61, 61);
        --color-tertiary: rgb(209, 209, 209);
        --color-tertiary-content: rgb(71, 71, 71);
        --color-input: rgb(228, 228, 228);
        --color-input-content: #333;

        --color-ongoing: grey;
        --color-unread: cornflowerblue;
        --color-unanswered: #9acd32;
        --color-ended: firebrick;

        --color-generic: #888;
        --color-generic-content: #000;

        --color-genre: var(--color-generic);
        --color-genre-content: var(--color-generic-content);
        --color-gender: var(--color-generic);
        --color-gender-content: var(--color-generic-content);
        --color-character: var(--color-generic);
        --color-character-content: var(--color-generic-content);
        --color-characteristic: var(--color-generic);
        --color-characteristic-content: var(--color-generic-content);
        --color-setting: var(--color-generic);
        --color-setting-content: var(--color-generic-content);
        --color-post-length: var(--color-generic);
        --color-post-length-content: var(--color-generic-content);
        --color-rp-length: var(--color-generic);
        --color-rp-length-content: var(--color-generic-content);
        --color-character-pref: var(--color-generic);
        --color-character-pref-content: var(--color-generic-content);
        --color-plot: var(--color-generic);
        --color-plot-content: var(--color-generic-content);
        --color-theme: var(--color-generic);
        --color-theme-content: var(--color-generic-content);
        --color-detail: var(--color-generic);
        --color-detail-content: var(--color-generic-content);

        --color-fandom: #424242;
        --color-fandom-content: #fff;

        --color-light-warning: var(--color-ended);
        --color-light-warning-content: #fff;

        --color-heavy-warning: var(--color-ended);
        --color-heavy-warning-content: #fff;

        --color-nav: var(--color-primary);
        --color-nav-content: var(--color-primary-content);

        --radius-primary: 5px;
        --radius-secondary: 10px;

        --home-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik0xNDcyIDk5MnY0ODBxMCAyNi0xOSA0NXQtNDUgMTloLTM4NHYtMzg0SDc2OHYzODRIMzg0cS0yNiAwLTQ1LTE5dC0xOS00NVY5OTJxMC0xIC41LTN0LjUtM2w1NzUtNDc0IDU3NSA0NzRxMSAyIDEgNnptMjIzLTY5LTYyIDc0cS04IDktMjEgMTFoLTNxLTEzIDAtMjEtN0w4OTYgNDI0bC02OTIgNTc3cS0xMiA4LTI0IDctMTMtMi0yMS0xMWwtNjItNzRxLTgtMTAtNy0yMy41dDExLTIxLjVsNzE5LTU5OXEzMi0yNiA3Ni0yNnQ3NiAyNmwyNDQgMjA0VjI4OHEwLTE0IDktMjN0MjMtOWgxOTJxMTQgMCAyMyA5dDkgMjN2NDA4bDIxOSAxODJxMTAgOCAxMSAyMS41dC03IDIzLjV6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --directory-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik04OTYgNzY4cTIzNyAwIDQ0My00M3QzMjUtMTI3djE3MHEwIDY5LTEwMyAxMjh0LTI4MCA5My41LTM4NSAzNC41LTM4NS0zNC41VDIzMSA4OTYgMTI4IDc2OFY1OThxMTE5IDg0IDMyNSAxMjd0NDQzIDQzem0wIDc2OHEyMzcgMCA0NDMtNDN0MzI1LTEyN3YxNzBxMCA2OS0xMDMgMTI4dC0yODAgOTMuNS0zODUgMzQuNS0zODUtMzQuNS0yODAtOTMuNS0xMDMtMTI4di0xNzBxMTE5IDg0IDMyNSAxMjd0NDQzIDQzem0wLTM4NHEyMzcgMCA0NDMtNDN0MzI1LTEyN3YxNzBxMCA2OS0xMDMgMTI4dC0yODAgOTMuNS0zODUgMzQuNS0zODUtMzQuNS0yODAtOTMuNS0xMDMtMTI4Vjk4MnExMTkgODQgMzI1IDEyN3Q0NDMgNDN6TTg5NiAwcTIwOCAwIDM4NSAzNC41dDI4MCA5My41IDEwMyAxMjh2MTI4cTAgNjktMTAzIDEyOHQtMjgwIDkzLjVUODk2IDY0MHQtMzg1LTM0LjVUMjMxIDUxMiAxMjggMzg0VjI1NnEwLTY5IDEwMy0xMjh0MjgwLTkzLjVUODk2IDB6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --notifications-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik02NDAgODk2cTAtNTMtMzcuNS05MC41VDUxMiA3Njh0LTkwLjUgMzcuNVQzODQgODk2dDM3LjUgOTAuNVQ1MTIgMTAyNHQ5MC41LTM3LjVUNjQwIDg5NnptMzg0IDBxMC01My0zNy41LTkwLjVUODk2IDc2OHQtOTAuNSAzNy41VDc2OCA4OTZ0MzcuNSA5MC41VDg5NiAxMDI0dDkwLjUtMzcuNVQxMDI0IDg5NnptMzg0IDBxMC01My0zNy41LTkwLjVUMTI4MCA3Njh0LTkwLjUgMzcuNVQxMTUyIDg5NnQzNy41IDkwLjUgOTAuNSAzNy41IDkwLjUtMzcuNVQxNDA4IDg5NnptMzg0IDBxMCAxNzQtMTIwIDMyMS41dC0zMjYgMjMzLTQ1MCA4NS41cS0xMTAgMC0yMTEtMTgtMTczIDE3My00MzUgMjI5LTUyIDEwLTg2IDEzLTEyIDEtMjItNnQtMTMtMThxLTQtMTUgMjAtMzcgNS01IDIzLjUtMjEuNVQxOTggMTY1NHQyMy41LTI1LjUgMjQtMzEuNSAyMC41LTM3IDIwLTQ4IDE0LjUtNTcuNVQzMTMgMTM4MnEtMTQ2LTkwLTIyOS41LTIxNi41VDAgODk2cTAtMTc0IDEyMC0zMjEuNXQzMjYtMjMzVDg5NiAyNTZ0NDUwIDg1LjUgMzI2IDIzM1QxNzkyIDg5NnoiIGZpbGw9IiNmZmYiLz48L3N2Zz4=);
        --admin-image: url(data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNzkyIiBoZWlnaHQ9IjE3OTIiIGZpbGw9IiNmZmYiIHhtbG5zOnY9Imh0dHBzOi8vdmVjdGEuaW8vbmFubyI+PHBhdGggdmVjdG9yLWVmZmVjdD0ibm9uLXNjYWxpbmctc3Ryb2tlIiBkPSJNLTg5Ni04OTZIODk2Vjg5NkgtODk2eiIgdmlzaWJpbGl0eT0iaGlkZGVuIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg4OTYgODk2KSIvPjxwYXRoIHZlY3Rvci1lZmZlY3Q9Im5vbi1zY2FsaW5nLXN0cm9rZSIgZD0iTS01NDAtNTQwSDU0MFY1NDBILTU0MHoiIHZpc2liaWxpdHk9ImhpZGRlbiIgdHJhbnNmb3JtPSJtYXRyaXgoMS42NiAwIDAgMS42NiA4OTYuNCA4OTYuNCkiLz48cGF0aCB2ZWN0b3ItZWZmZWN0PSJub24tc2NhbGluZy1zdHJva2UiIHRyYW5zZm9ybT0ibWF0cml4KDI1LjA1IDAgMCAyNy43MiAtMS42MTg1IC05OC44MjA4KSIgZD0iTTY4LjggNDIuN2MtOC41LTYuMi0xNy43LTExLjMtMjcuMS0xNi4yLS4xIDAtLjIgMC0uMy0uMS0uMi4yLS40LjUtLjcuOGwtMi4yLTFjLS41LS4yLS43LS44LS40LTEuM2wyLjEtMy4zYy4yLS40LjctLjUgMS4xLS40IDEuNC41IDIuNi0uMSAzLjYtMS44IDEuMy0yLjEgMS4xLTMuNi0xLTQuOUwyOC41IDQuN2MtLjYtLjQtMS4zLS42LTEuNi0uN0MyNSA0IDIzLjYgNS4zIDIzIDcuMWMtLjMuOS0uMiAxLjguMyAyLjYuMi4zLjIuNyAwIDEuMWwtNi4yIDkuN2MtLjUuNy0xLjcgMi4xLTEuOCAyLjEtMS43LS42LTMuMi4zLTQuMiAyLjQtLjggMS43LS40IDMuMSAxLjMgNC4zTDI3LjcgMzljMS4yLjcgMi40IDEuMiAzLjYuNHMyLTIgMi4zLTMuOGMwLS4zIDAtLjYtLjItLjhhMy4wNCAzLjA0IDAgMCAwLS41LS43Yy0uMi0uMy0uMy0uOCAwLTEuMWwyLjQtMy44Yy4zLS41LjktLjYgMS4zLS4yLjguNyAxLjggMSAxLjYgMi4yLS4xLjMuMS43LjMuOSA4LjUgNi4zIDE3IDEyLjYgMjYuNCAxNy42IDIgMSA0IC42IDUuOC0uNC4zLS4xLjUtLjYuNS0xIC4yLTIuMi0uNS00LjItMi40LTUuNnoiLz48cGF0aCB2ZWN0b3ItZWZmZWN0PSJub24tc2NhbGluZy1zdHJva2UiIHRyYW5zZm9ybT0ibWF0cml4KDI1LjA1IDAgMCAyNy43MiAtLjAxIC0xMDUuMjAxNikiIGQ9Ik0zOC45IDYxLjNoLTIuNWMtLjQgMC0uOC0uNC0uOC0uOCAwLTIuNy0xLTMuOS0zLjUtMy45LTcuOS0uMS0xNS43IDAtMjMuNiAwLS4zIDAtLjcuMS0xIC4xLTEuNi4zLTIuNSAxLjQtMi42IDIuOXYxYzAgLjUtLjQuOS0uOC45SDEuNGMtLjUgMC0uOC40LS44Ljh2NC45YzAgLjQuMy44LjguOGguMiAwIDM3LjMgMCAuMWMuNCAwIC44LS40LjgtLjh2LTVjLS4xLS41LS40LS45LS45LS45eiIvPjwvc3ZnPg==);
        --user-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik0xMTUyIDg5NnEwLTEwNi03NS0xODF0LTE4MS03NS0xODEgNzUtNzUgMTgxIDc1IDE4MSAxODEgNzUgMTgxLTc1IDc1LTE4MXptNTEyLTEwOXYyMjJxMCAxMi04IDIzdC0yMCAxM2wtMTg1IDI4cS0xOSA1NC0zOSA5MSAzNSA1MCAxMDcgMTM4IDEwIDEyIDEwIDI1dC05IDIzcS0yNyAzNy05OSAxMDh0LTk0IDcxcS0xMiAwLTI2LTlsLTEzOC0xMDhxLTQ0IDIzLTkxIDM4LTE2IDEzNi0yOSAxODYtNyAyOC0zNiAyOEg3ODVxLTE0IDAtMjQuNS04LjVUNzQ5IDE2MzRsLTI4LTE4NHEtNDktMTYtOTAtMzdsLTE0MSAxMDdxLTEwIDktMjUgOS0xNCAwLTI1LTExLTEyNi0xMTQtMTY1LTE2OC03LTEwLTctMjMgMC0xMiA4LTIzIDE1LTIxIDUxLTY2LjV0NTQtNzAuNXEtMjctNTAtNDEtOTlsLTE4My0yN3EtMTMtMi0yMS0xMi41dC04LTIzLjVWNzgzcTAtMTIgOC0yM3QxOS0xM2wxODYtMjhxMTQtNDYgMzktOTItNDAtNTctMTA3LTEzOC0xMC0xMi0xMC0yNCAwLTEwIDktMjMgMjYtMzYgOTguNS0xMDcuNVQ0NjUgMjYzcTEzIDAgMjYgMTBsMTM4IDEwN3E0NC0yMyA5MS0zOCAxNi0xMzYgMjktMTg2IDctMjggMzYtMjhoMjIycTE0IDAgMjQuNSA4LjVUMTA0MyAxNThsMjggMTg0cTQ5IDE2IDkwIDM3bDE0Mi0xMDdxOS05IDI0LTkgMTMgMCAyNSAxMCAxMjkgMTE5IDE2NSAxNzAgNyA4IDcgMjIgMCAxMi04IDIzLTE1IDIxLTUxIDY2LjV0LTU0IDcwLjVxMjYgNTAgNDEgOThsMTgzIDI4cTEzIDIgMjEgMTIuNXQ4IDIzLjV6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --donate-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iOCIgaGVpZ2h0PSI4IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0tMS0xaDgwMnY2MDJILTF6Ii8+PGc+PHBhdGggZD0iTTMuNTA1IDB2MWgtLjc1Yy0uNjggMC0xLjI1LjU3LTEuMjUgMS4yNXYuNWMwIC42OC40NCAxLjI0IDEuMDkgMS40MWwyLjU2LjY2Yy4xNC4wNC4zNC4yOS4zNC40NHYuNWMwIC4xNC0uMTEuMjUtLjI1LjI1aC0yLjVhLjU2LjU2IDAgMCAxLS4yNS0uMDZ2LS45NGgtMXYxYzAgLjM0LjIuNjMuNDQuNzguMjMuMTYuNTIuMjIuODEuMjJoLjc1djFoMXYtMWguNzVjLjY5IDAgMS4yNS0uNTYgMS4yNS0xLjI1di0uNWMwLS42OC0uNDQtMS4yNC0xLjA5LTEuNDFsLTIuNTYtLjY2Yy0uMTQtLjA0LS4zNC0uMjktLjM0LS40NHYtLjVjMC0uMTQuMTEtLjI1LjI1LS4yNWgyLjVjLjExIDAgLjIxLjA0LjI1LjA2VjNoMVYyYzAtLjM0LS4yLS42My0uNDQtLjc4LS4yMy0uMTYtLjUyLS4yMi0uODEtLjIyaC0uNzVWMGgtMXoiIGZpbGw9IiNmZmYiLz48L2c+PC9zdmc+);
        --use-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyBhcmlhLWhpZGRlbj0idHJ1ZSIgZGF0YS1wcmVmaXg9ImZhcyIgZGF0YS1pY29uPSJzY3JvbGwiIGNsYXNzPSJzdmctaW5saW5lLS1mYSBmYS1zY3JvbGwgZmEtdy0yMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgNjQwIDUxMiI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTQ4IDBDMjEuNTMgMCAwIDIxLjUzIDAgNDh2NjRjMCA4Ljg0IDcuMTYgMTYgMTYgMTZoODBWNDhDOTYgMjEuNTMgNzQuNDcgMCA0OCAwem0yMDggNDEyLjU3VjM1MmgyODhWOTZjMC01Mi45NC00My4wNi05Ni05Ni05NkgxMTEuNTlDMTIxLjc0IDEzLjQxIDEyOCAyOS45MiAxMjggNDh2MzY4YzAgMzguODcgMzQuNjUgNjkuNjUgNzQuNzUgNjMuMTJDMjM0LjIyIDQ3NCAyNTYgNDQ0LjQ2IDI1NiA0MTIuNTd6TTI4OCAzODR2MzJjMCA1Mi45My00My4wNiA5Ni05NiA5NmgzMzZjNjEuODYgMCAxMTItNTAuMTQgMTEyLTExMiAwLTguODQtNy4xNi0xNi0xNi0xNkgyODh6Ii8+PC9zdmc+);
        --discord-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNTAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0ibm9uZSIgZD0iTS0xLTFoNTJ2NDJILTF6Ii8+PGc+PHBhdGggZD0iTTQyLjEyNiA2Ljc2OGMtMy45ODItMy4yLTEwLjI3OS0zLjc0My0xMC41NDYtMy43NjVhLjk5OS45OTkgMCAwIDAtLjk5Mi41ODdjLS4wMTIuMDI1LS4xNS4zNC0uMzAzLjgzMyAyLjYzMy40NDMgNS44NjcgMS4zNCA4Ljc5NCAzLjE1NWExIDEgMCAwIDEtMS4wNTUgMS43QzMyLjk5NCA2LjE1OCAyNi43MDkgNiAyNS41IDZzLTcuNDk1LjE1OC0xMi41MjMgMy4yNzhhMSAxIDAgMSAxLTEuMDU1LTEuNjk5YzIuOTI3LTEuODE1IDYuMTYtMi43MTIgOC43OTQtMy4xNTVhOC40OSA4LjQ5IDAgMCAwLS4zMDMtLjgzMy45ODkuOTg5IDAgMCAwLS45OTMtLjU4N2MtLjI2Ni4wMjEtNi41NjMuNTYzLTEwLjU5OCAzLjgxQzYuNzEzIDguNzYgMi41IDIwLjE1MSAyLjUgMzBjMCAuMTc0LjA0NS4zNDQuMTMxLjQ5NUM1LjU0IDM1LjYwNSAxMy40NzMgMzYuOTQyIDE1LjI4IDM3bC4wMzIuMDAxYy4zMTkgMCAuNjItLjE1Mi44MDktLjQxbDEuODI5LTIuNTE0Yy00LjkzMy0xLjI3Ni03LjQ1My0zLjQzOS03LjU5OC0zLjU2OGEuOTk5Ljk5OSAwIDAgMSAxLjMyMy0xLjVjLjA2MS4wNTQgNC43IDMuOTkyIDEzLjgyNSAzLjk5MiA5LjE0MSAwIDEzLjc4Mi0zLjk1MyAxMy44MjgtMy45OTNhMSAxIDAgMCAxIDEuMzIxIDEuNTAxYy0uMTQ2LjEzLTIuNjY2IDIuMjkyLTcuNTk5IDMuNTY4bDEuODI5IDIuNTEzYy4xODkuMjYuNDkuNDExLjgwOS40MTFoLjAzMWMxLjgwOS0uMDU4IDkuNzQxLTEuMzk2IDEyLjY0OS02LjUwNUEuOTg5Ljk4OSAwIDAgMCA0OC41IDMwYzAtOS44NDgtNC4yMTMtMjEuMjQtNi4zNzQtMjMuMjMyek0xOSAyNmMtMS45MzMgMC0zLjUtMS43OS0zLjUtNCAwLTIuMjA5IDEuNTY3LTQgMy41LTRzMy41IDEuNzkxIDMuNSA0YzAgMi4yMS0xLjU2NyA0LTMuNSA0em0xMyAwYy0xLjkzMyAwLTMuNS0xLjc5LTMuNS00IDAtMi4yMDkgMS41NjctNCAzLjUtNHMzLjUgMS43OTEgMy41IDRjMCAyLjIxLTEuNTY3IDQtMy41IDR6IiBmaWxsPSIjZmZmIi8+PC9nPjwvc3ZnPg==);
        --logout-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB2aWV3Qm94PSIwIDAgNTMuNzYgNTMuNzYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgZmlsbD0iIzAwMDAwMCI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTEzLjQ0IDQuNDhhNi43MiA2LjcyIDAgMCAwIC02LjcyIDYuNzJ2MzEuMzZhNi43MiA2LjcyIDAgMCAwIDYuNzIgNi43MmgxMy40NGE2LjcyIDYuNzIgMCAwIDAgNi43MiAtNi43MlYxMS4yYTYuNzIgNi43MiAwIDAgMCAtNi43MiAtNi43MnptMjMuMDU2IDExLjg1NmEyLjI0IDIuMjQgMCAwIDEgMy4xNjcgMGw4Ljk2IDguOTZhMi4yNCAyLjI0IDAgMCAxIDAgMy4xNjdsLTguOTYgOC45NmEyLjI0IDIuMjQgMCAwIDEgLTMuMTY3IC0zLjE2N0w0MS42MzMgMjkuMTJIMjIuNGEyLjI0IDIuMjQgMCAxIDEgMCAtNC40OGgxOS4yMzNsLTUuMTM2IC01LjEzNmEyLjI0IDIuMjQgMCAwIDEgMCAtMy4xNjciLz48L3N2Zz4=);
        --login-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MnB4IiBoZWlnaHQ9IjE3OTJweCIgdmlld0JveD0iMCAwIDUzLjc2IDUzLjc2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGZpbGw9Im5vbmUiPjxwYXRoIGZpbGw9IiNmZmYiIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTI0LjY0IDQuNDhhNi43MiA2LjcyIDAgMCAwIC02LjcyIDYuNzJ2MzEuMzZhNi43MiA2LjcyIDAgMCAwIDYuNzIgNi43MmgxMy40NGE2LjcyIDYuNzIgMCAwIDAgNi43MiAtNi43MlYxMS4yYTYuNzIgNi43MiAwIDAgMCAtNi43MiAtNi43MnptMi44OTYgMTQuMDk2YTIuMjQgMi4yNCAwIDAgMSAzLjE2NyAwbDYuNzIgNi43MmEyLjI0IDIuMjQgMCAwIDEgMCAzLjE2N2wtNi43MiA2LjcyYTIuMjQgMi4yNCAwIDAgMSAtMy4xNjcgLTMuMTY3TDMwLjQzMyAyOS4xMkgxMS4yYTIuMjQgMi4yNCAwIDEgMSAwIC00LjQ4aDE5LjIzM2wtMi44OTYgLTIuODk2YTIuMjQgMi4yNCAwIDAgMSAwIC0zLjE2NyIgY2xpcC1ydWxlPSJldmVub2RkIi8+PC9zdmc+);
        --register-image: url(data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmIiB3aWR0aD0iMTc5MnB4IiBoZWlnaHQ9IjE3OTJweCIgdmlld0JveD0iMCAwIDUzLjc2IDUzLjc2IiB2ZXJzaW9uPSIxLjIiIGJhc2VQcm9maWxlPSJ0aW55IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik00MC4zMiAyMi40aC04Ljk2VjEzLjQ0YTQuNDggNC40OCAwIDAgMCAtOC45NiAwbDAuMTU5IDguOTZIMTMuNDRhNC40OCA0LjQ4IDAgMCAwIDAgOC45Nmw5LjExOSAtMC4xNTlMMjIuNCA0MC4zMmE0LjQ4IDQuNDggMCAwIDAgOC45NiAwdi05LjExOUw0MC4zMiAzMS4zNmE0LjQ4IDQuNDggMCAwIDAgMCAtOC45NiIvPjwvc3ZnPg==);
      }

      [data-theme='dark'] {
        --color-primary: #d6d6d6;
        --color-primary-content: rgb(44, 44, 44);
        --color-header: #9c9c9c;
        --color-header-content: #5c5959;
        --color-secondary: #bebebe;
        --color-secondary-content: rgb(61, 61, 61);
        --color-tertiary: rgb(209, 209, 209);
        --color-tertiary-content: rgb(71, 71, 71);
        --color-input: rgb(228, 228, 228);
        --color-input-content: #333;

        --color-ongoing: grey;
        --color-unread: cornflowerblue;
        --color-unanswered: #9acd32;
        --color-ended: firebrick;

        --color-generic: #888;
        --color-generic-content: #000;

        --color-genre: var(--color-generic);
        --color-genre-content: var(--color-generic-content);
        --color-gender: var(--color-generic);
        --color-gender-content: var(--color-generic-content);
        --color-character: var(--color-generic);
        --color-character-content: var(--color-generic-content);
        --color-characteristic: var(--color-generic);
        --color-characteristic-content: var(--color-generic-content);
        --color-setting: var(--color-generic);
        --color-setting-content: var(--color-generic-content);
        --color-post-length: var(--color-generic);
        --color-post-length-content: var(--color-generic-content);
        --color-rp-length: var(--color-generic);
        --color-rp-length-content: var(--color-generic-content);
        --color-character-pref: var(--color-generic);
        --color-character-pref-content: var(--color-generic-content);
        --color-plot: var(--color-generic);
        --color-plot-content: var(--color-generic-content);
        --color-theme: var(--color-generic);
        --color-theme-content: var(--color-generic-content);
        --color-detail: var(--color-generic);
        --color-detail-content: var(--color-generic-content);

        --color-fandom: #424242;
        --color-fandom-content: #fff;

        --color-light-warning: var(--color-ended);
        --color-light-warning-content: #fff;

        --color-heavy-warning: var(--color-ended);
        --color-heavy-warning-content: #fff;

        --color-nav: var(--color-primary);
        --color-nav-content: var(--color-primary-content);

        --radius-primary: 5px;
        --radius-secondary: 10px;

        --home-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik0xNDcyIDk5MnY0ODBxMCAyNi0xOSA0NXQtNDUgMTloLTM4NHYtMzg0SDc2OHYzODRIMzg0cS0yNiAwLTQ1LTE5dC0xOS00NVY5OTJxMC0xIC41LTN0LjUtM2w1NzUtNDc0IDU3NSA0NzRxMSAyIDEgNnptMjIzLTY5LTYyIDc0cS04IDktMjEgMTFoLTNxLTEzIDAtMjEtN0w4OTYgNDI0bC02OTIgNTc3cS0xMiA4LTI0IDctMTMtMi0yMS0xMWwtNjItNzRxLTgtMTAtNy0yMy41dDExLTIxLjVsNzE5LTU5OXEzMi0yNiA3Ni0yNnQ3NiAyNmwyNDQgMjA0VjI4OHEwLTE0IDktMjN0MjMtOWgxOTJxMTQgMCAyMyA5dDkgMjN2NDA4bDIxOSAxODJxMTAgOCAxMSAyMS41dC03IDIzLjV6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --directory-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik04OTYgNzY4cTIzNyAwIDQ0My00M3QzMjUtMTI3djE3MHEwIDY5LTEwMyAxMjh0LTI4MCA5My41LTM4NSAzNC41LTM4NS0zNC41VDIzMSA4OTYgMTI4IDc2OFY1OThxMTE5IDg0IDMyNSAxMjd0NDQzIDQzem0wIDc2OHEyMzcgMCA0NDMtNDN0MzI1LTEyN3YxNzBxMCA2OS0xMDMgMTI4dC0yODAgOTMuNS0zODUgMzQuNS0zODUtMzQuNS0yODAtOTMuNS0xMDMtMTI4di0xNzBxMTE5IDg0IDMyNSAxMjd0NDQzIDQzem0wLTM4NHEyMzcgMCA0NDMtNDN0MzI1LTEyN3YxNzBxMCA2OS0xMDMgMTI4dC0yODAgOTMuNS0zODUgMzQuNS0zODUtMzQuNS0yODAtOTMuNS0xMDMtMTI4Vjk4MnExMTkgODQgMzI1IDEyN3Q0NDMgNDN6TTg5NiAwcTIwOCAwIDM4NSAzNC41dDI4MCA5My41IDEwMyAxMjh2MTI4cTAgNjktMTAzIDEyOHQtMjgwIDkzLjVUODk2IDY0MHQtMzg1LTM0LjVUMjMxIDUxMiAxMjggMzg0VjI1NnEwLTY5IDEwMy0xMjh0MjgwLTkzLjVUODk2IDB6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --notifications-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik02NDAgODk2cTAtNTMtMzcuNS05MC41VDUxMiA3Njh0LTkwLjUgMzcuNVQzODQgODk2dDM3LjUgOTAuNVQ1MTIgMTAyNHQ5MC41LTM3LjVUNjQwIDg5NnptMzg0IDBxMC01My0zNy41LTkwLjVUODk2IDc2OHQtOTAuNSAzNy41VDc2OCA4OTZ0MzcuNSA5MC41VDg5NiAxMDI0dDkwLjUtMzcuNVQxMDI0IDg5NnptMzg0IDBxMC01My0zNy41LTkwLjVUMTI4MCA3Njh0LTkwLjUgMzcuNVQxMTUyIDg5NnQzNy41IDkwLjUgOTAuNSAzNy41IDkwLjUtMzcuNVQxNDA4IDg5NnptMzg0IDBxMCAxNzQtMTIwIDMyMS41dC0zMjYgMjMzLTQ1MCA4NS41cS0xMTAgMC0yMTEtMTgtMTczIDE3My00MzUgMjI5LTUyIDEwLTg2IDEzLTEyIDEtMjItNnQtMTMtMThxLTQtMTUgMjAtMzcgNS01IDIzLjUtMjEuNVQxOTggMTY1NHQyMy41LTI1LjUgMjQtMzEuNSAyMC41LTM3IDIwLTQ4IDE0LjUtNTcuNVQzMTMgMTM4MnEtMTQ2LTkwLTIyOS41LTIxNi41VDAgODk2cTAtMTc0IDEyMC0zMjEuNXQzMjYtMjMzVDg5NiAyNTZ0NDUwIDg1LjUgMzI2IDIzM1QxNzkyIDg5NnoiIGZpbGw9IiNmZmYiLz48L3N2Zz4=);
        --admin-image: url(data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNzkyIiBoZWlnaHQ9IjE3OTIiIGZpbGw9IiNmZmYiIHhtbG5zOnY9Imh0dHBzOi8vdmVjdGEuaW8vbmFubyI+PHBhdGggdmVjdG9yLWVmZmVjdD0ibm9uLXNjYWxpbmctc3Ryb2tlIiBkPSJNLTg5Ni04OTZIODk2Vjg5NkgtODk2eiIgdmlzaWJpbGl0eT0iaGlkZGVuIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg4OTYgODk2KSIvPjxwYXRoIHZlY3Rvci1lZmZlY3Q9Im5vbi1zY2FsaW5nLXN0cm9rZSIgZD0iTS01NDAtNTQwSDU0MFY1NDBILTU0MHoiIHZpc2liaWxpdHk9ImhpZGRlbiIgdHJhbnNmb3JtPSJtYXRyaXgoMS42NiAwIDAgMS42NiA4OTYuNCA4OTYuNCkiLz48cGF0aCB2ZWN0b3ItZWZmZWN0PSJub24tc2NhbGluZy1zdHJva2UiIHRyYW5zZm9ybT0ibWF0cml4KDI1LjA1IDAgMCAyNy43MiAtMS42MTg1IC05OC44MjA4KSIgZD0iTTY4LjggNDIuN2MtOC41LTYuMi0xNy43LTExLjMtMjcuMS0xNi4yLS4xIDAtLjIgMC0uMy0uMS0uMi4yLS40LjUtLjcuOGwtMi4yLTFjLS41LS4yLS43LS44LS40LTEuM2wyLjEtMy4zYy4yLS40LjctLjUgMS4xLS40IDEuNC41IDIuNi0uMSAzLjYtMS44IDEuMy0yLjEgMS4xLTMuNi0xLTQuOUwyOC41IDQuN2MtLjYtLjQtMS4zLS42LTEuNi0uN0MyNSA0IDIzLjYgNS4zIDIzIDcuMWMtLjMuOS0uMiAxLjguMyAyLjYuMi4zLjIuNyAwIDEuMWwtNi4yIDkuN2MtLjUuNy0xLjcgMi4xLTEuOCAyLjEtMS43LS42LTMuMi4zLTQuMiAyLjQtLjggMS43LS40IDMuMSAxLjMgNC4zTDI3LjcgMzljMS4yLjcgMi40IDEuMiAzLjYuNHMyLTIgMi4zLTMuOGMwLS4zIDAtLjYtLjItLjhhMy4wNCAzLjA0IDAgMCAwLS41LS43Yy0uMi0uMy0uMy0uOCAwLTEuMWwyLjQtMy44Yy4zLS41LjktLjYgMS4zLS4yLjguNyAxLjggMSAxLjYgMi4yLS4xLjMuMS43LjMuOSA4LjUgNi4zIDE3IDEyLjYgMjYuNCAxNy42IDIgMSA0IC42IDUuOC0uNC4zLS4xLjUtLjYuNS0xIC4yLTIuMi0uNS00LjItMi40LTUuNnoiLz48cGF0aCB2ZWN0b3ItZWZmZWN0PSJub24tc2NhbGluZy1zdHJva2UiIHRyYW5zZm9ybT0ibWF0cml4KDI1LjA1IDAgMCAyNy43MiAtLjAxIC0xMDUuMjAxNikiIGQ9Ik0zOC45IDYxLjNoLTIuNWMtLjQgMC0uOC0uNC0uOC0uOCAwLTIuNy0xLTMuOS0zLjUtMy45LTcuOS0uMS0xNS43IDAtMjMuNiAwLS4zIDAtLjcuMS0xIC4xLTEuNi4zLTIuNSAxLjQtMi42IDIuOXYxYzAgLjUtLjQuOS0uOC45SDEuNGMtLjUgMC0uOC40LS44Ljh2NC45YzAgLjQuMy44LjguOGguMiAwIDM3LjMgMCAuMWMuNCAwIC44LS40LjgtLjh2LTVjLS4xLS41LS40LS45LS45LS45eiIvPjwvc3ZnPg==);
        --user-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik0xMTUyIDg5NnEwLTEwNi03NS0xODF0LTE4MS03NS0xODEgNzUtNzUgMTgxIDc1IDE4MSAxODEgNzUgMTgxLTc1IDc1LTE4MXptNTEyLTEwOXYyMjJxMCAxMi04IDIzdC0yMCAxM2wtMTg1IDI4cS0xOSA1NC0zOSA5MSAzNSA1MCAxMDcgMTM4IDEwIDEyIDEwIDI1dC05IDIzcS0yNyAzNy05OSAxMDh0LTk0IDcxcS0xMiAwLTI2LTlsLTEzOC0xMDhxLTQ0IDIzLTkxIDM4LTE2IDEzNi0yOSAxODYtNyAyOC0zNiAyOEg3ODVxLTE0IDAtMjQuNS04LjVUNzQ5IDE2MzRsLTI4LTE4NHEtNDktMTYtOTAtMzdsLTE0MSAxMDdxLTEwIDktMjUgOS0xNCAwLTI1LTExLTEyNi0xMTQtMTY1LTE2OC03LTEwLTctMjMgMC0xMiA4LTIzIDE1LTIxIDUxLTY2LjV0NTQtNzAuNXEtMjctNTAtNDEtOTlsLTE4My0yN3EtMTMtMi0yMS0xMi41dC04LTIzLjVWNzgzcTAtMTIgOC0yM3QxOS0xM2wxODYtMjhxMTQtNDYgMzktOTItNDAtNTctMTA3LTEzOC0xMC0xMi0xMC0yNCAwLTEwIDktMjMgMjYtMzYgOTguNS0xMDcuNVQ0NjUgMjYzcTEzIDAgMjYgMTBsMTM4IDEwN3E0NC0yMyA5MS0zOCAxNi0xMzYgMjktMTg2IDctMjggMzYtMjhoMjIycTE0IDAgMjQuNSA4LjVUMTA0MyAxNThsMjggMTg0cTQ5IDE2IDkwIDM3bDE0Mi0xMDdxOS05IDI0LTkgMTMgMCAyNSAxMCAxMjkgMTE5IDE2NSAxNzAgNyA4IDcgMjIgMCAxMi04IDIzLTE1IDIxLTUxIDY2LjV0LTU0IDcwLjVxMjYgNTAgNDEgOThsMTgzIDI4cTEzIDIgMjEgMTIuNXQ4IDIzLjV6IiBmaWxsPSIjZmZmIi8+PC9zdmc+);
        --donate-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iOCIgaGVpZ2h0PSI4IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0tMS0xaDgwMnY2MDJILTF6Ii8+PGc+PHBhdGggZD0iTTMuNTA1IDB2MWgtLjc1Yy0uNjggMC0xLjI1LjU3LTEuMjUgMS4yNXYuNWMwIC42OC40NCAxLjI0IDEuMDkgMS40MWwyLjU2LjY2Yy4xNC4wNC4zNC4yOS4zNC40NHYuNWMwIC4xNC0uMTEuMjUtLjI1LjI1aC0yLjVhLjU2LjU2IDAgMCAxLS4yNS0uMDZ2LS45NGgtMXYxYzAgLjM0LjIuNjMuNDQuNzguMjMuMTYuNTIuMjIuODEuMjJoLjc1djFoMXYtMWguNzVjLjY5IDAgMS4yNS0uNTYgMS4yNS0xLjI1di0uNWMwLS42OC0uNDQtMS4yNC0xLjA5LTEuNDFsLTIuNTYtLjY2Yy0uMTQtLjA0LS4zNC0uMjktLjM0LS40NHYtLjVjMC0uMTQuMTEtLjI1LjI1LS4yNWgyLjVjLjExIDAgLjIxLjA0LjI1LjA2VjNoMVYyYzAtLjM0LS4yLS42My0uNDQtLjc4LS4yMy0uMTYtLjUyLS4yMi0uODEtLjIyaC0uNzVWMGgtMXoiIGZpbGw9IiNmZmYiLz48L2c+PC9zdmc+);
        --use-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyBhcmlhLWhpZGRlbj0idHJ1ZSIgZGF0YS1wcmVmaXg9ImZhcyIgZGF0YS1pY29uPSJzY3JvbGwiIGNsYXNzPSJzdmctaW5saW5lLS1mYSBmYS1zY3JvbGwgZmEtdy0yMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgNjQwIDUxMiI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTQ4IDBDMjEuNTMgMCAwIDIxLjUzIDAgNDh2NjRjMCA4Ljg0IDcuMTYgMTYgMTYgMTZoODBWNDhDOTYgMjEuNTMgNzQuNDcgMCA0OCAwem0yMDggNDEyLjU3VjM1MmgyODhWOTZjMC01Mi45NC00My4wNi05Ni05Ni05NkgxMTEuNTlDMTIxLjc0IDEzLjQxIDEyOCAyOS45MiAxMjggNDh2MzY4YzAgMzguODcgMzQuNjUgNjkuNjUgNzQuNzUgNjMuMTJDMjM0LjIyIDQ3NCAyNTYgNDQ0LjQ2IDI1NiA0MTIuNTd6TTI4OCAzODR2MzJjMCA1Mi45My00My4wNiA5Ni05NiA5NmgzMzZjNjEuODYgMCAxMTItNTAuMTQgMTEyLTExMiAwLTguODQtNy4xNi0xNi0xNi0xNkgyODh6Ii8+PC9zdmc+);
        --discord-image: url(data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNTAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0ibm9uZSIgZD0iTS0xLTFoNTJ2NDJILTF6Ii8+PGc+PHBhdGggZD0iTTQyLjEyNiA2Ljc2OGMtMy45ODItMy4yLTEwLjI3OS0zLjc0My0xMC41NDYtMy43NjVhLjk5OS45OTkgMCAwIDAtLjk5Mi41ODdjLS4wMTIuMDI1LS4xNS4zNC0uMzAzLjgzMyAyLjYzMy40NDMgNS44NjcgMS4zNCA4Ljc5NCAzLjE1NWExIDEgMCAwIDEtMS4wNTUgMS43QzMyLjk5NCA2LjE1OCAyNi43MDkgNiAyNS41IDZzLTcuNDk1LjE1OC0xMi41MjMgMy4yNzhhMSAxIDAgMSAxLTEuMDU1LTEuNjk5YzIuOTI3LTEuODE1IDYuMTYtMi43MTIgOC43OTQtMy4xNTVhOC40OSA4LjQ5IDAgMCAwLS4zMDMtLjgzMy45ODkuOTg5IDAgMCAwLS45OTMtLjU4N2MtLjI2Ni4wMjEtNi41NjMuNTYzLTEwLjU5OCAzLjgxQzYuNzEzIDguNzYgMi41IDIwLjE1MSAyLjUgMzBjMCAuMTc0LjA0NS4zNDQuMTMxLjQ5NUM1LjU0IDM1LjYwNSAxMy40NzMgMzYuOTQyIDE1LjI4IDM3bC4wMzIuMDAxYy4zMTkgMCAuNjItLjE1Mi44MDktLjQxbDEuODI5LTIuNTE0Yy00LjkzMy0xLjI3Ni03LjQ1My0zLjQzOS03LjU5OC0zLjU2OGEuOTk5Ljk5OSAwIDAgMSAxLjMyMy0xLjVjLjA2MS4wNTQgNC43IDMuOTkyIDEzLjgyNSAzLjk5MiA5LjE0MSAwIDEzLjc4Mi0zLjk1MyAxMy44MjgtMy45OTNhMSAxIDAgMCAxIDEuMzIxIDEuNTAxYy0uMTQ2LjEzLTIuNjY2IDIuMjkyLTcuNTk5IDMuNTY4bDEuODI5IDIuNTEzYy4xODkuMjYuNDkuNDExLjgwOS40MTFoLjAzMWMxLjgwOS0uMDU4IDkuNzQxLTEuMzk2IDEyLjY0OS02LjUwNUEuOTg5Ljk4OSAwIDAgMCA0OC41IDMwYzAtOS44NDgtNC4yMTMtMjEuMjQtNi4zNzQtMjMuMjMyek0xOSAyNmMtMS45MzMgMC0zLjUtMS43OS0zLjUtNCAwLTIuMjA5IDEuNTY3LTQgMy41LTRzMy41IDEuNzkxIDMuNSA0YzAgMi4yMS0xLjU2NyA0LTMuNSA0em0xMyAwYy0xLjkzMyAwLTMuNS0xLjc5LTMuNS00IDAtMi4yMDkgMS41NjctNCAzLjUtNHMzLjUgMS43OTEgMy41IDRjMCAyLjIxLTEuNTY3IDQtMy41IDR6IiBmaWxsPSIjZmZmIi8+PC9nPjwvc3ZnPg==);
        --logout-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MiIgaGVpZ2h0PSIxNzkyIiB2aWV3Qm94PSIwIDAgNTMuNzYgNTMuNzYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgZmlsbD0iIzAwMDAwMCI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTEzLjQ0IDQuNDhhNi43MiA2LjcyIDAgMCAwIC02LjcyIDYuNzJ2MzEuMzZhNi43MiA2LjcyIDAgMCAwIDYuNzIgNi43MmgxMy40NGE2LjcyIDYuNzIgMCAwIDAgNi43MiAtNi43MlYxMS4yYTYuNzIgNi43MiAwIDAgMCAtNi43MiAtNi43MnptMjMuMDU2IDExLjg1NmEyLjI0IDIuMjQgMCAwIDEgMy4xNjcgMGw4Ljk2IDguOTZhMi4yNCAyLjI0IDAgMCAxIDAgMy4xNjdsLTguOTYgOC45NmEyLjI0IDIuMjQgMCAwIDEgLTMuMTY3IC0zLjE2N0w0MS42MzMgMjkuMTJIMjIuNGEyLjI0IDIuMjQgMCAxIDEgMCAtNC40OGgxOS4yMzNsLTUuMTM2IC01LjEzNmEyLjI0IDIuMjQgMCAwIDEgMCAtMy4xNjciLz48L3N2Zz4=);
        --login-image: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTc5MnB4IiBoZWlnaHQ9IjE3OTJweCIgdmlld0JveD0iMCAwIDUzLjc2IDUzLjc2IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGZpbGw9Im5vbmUiPjxwYXRoIGZpbGw9IiNmZmYiIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTI0LjY0IDQuNDhhNi43MiA2LjcyIDAgMCAwIC02LjcyIDYuNzJ2MzEuMzZhNi43MiA2LjcyIDAgMCAwIDYuNzIgNi43MmgxMy40NGE2LjcyIDYuNzIgMCAwIDAgNi43MiAtNi43MlYxMS4yYTYuNzIgNi43MiAwIDAgMCAtNi43MiAtNi43MnptMi44OTYgMTQuMDk2YTIuMjQgMi4yNCAwIDAgMSAzLjE2NyAwbDYuNzIgNi43MmEyLjI0IDIuMjQgMCAwIDEgMCAzLjE2N2wtNi43MiA2LjcyYTIuMjQgMi4yNCAwIDAgMSAtMy4xNjcgLTMuMTY3TDMwLjQzMyAyOS4xMkgxMS4yYTIuMjQgMi4yNCAwIDEgMSAwIC00LjQ4aDE5LjIzM2wtMi44OTYgLTIuODk2YTIuMjQgMi4yNCAwIDAgMSAwIC0zLjE2NyIgY2xpcC1ydWxlPSJldmVub2RkIi8+PC9zdmc+);
        --register-image: url(data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmIiB3aWR0aD0iMTc5MnB4IiBoZWlnaHQ9IjE3OTJweCIgdmlld0JveD0iMCAwIDUzLjc2IDUzLjc2IiB2ZXJzaW9uPSIxLjIiIGJhc2VQcm9maWxlPSJ0aW55IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXRoIGQ9Ik00MC4zMiAyMi40aC04Ljk2VjEzLjQ0YTQuNDggNC40OCAwIDAgMCAtOC45NiAwbDAuMTU5IDguOTZIMTMuNDRhNC40OCA0LjQ4IDAgMCAwIDAgOC45Nmw5LjExOSAtMC4xNTlMMjIuNCA0MC4zMmE0LjQ4IDQuNDggMCAwIDAgOC45NiAwdi05LjExOUw0MC4zMiAzMS4zNmE0LjQ4IDQuNDggMCAwIDAgMCAtOC45NiIvPjwvc3ZnPg==);
      }
    CSS
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_theme
    @theme = Theme.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme).permit(:title, :public, :system, :css)
  end
end
