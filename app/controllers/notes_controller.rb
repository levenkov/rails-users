class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: [:show, :update, :destroy]

  def index
    @notes = current_user.notes.includes(:note_tags, :note_points)
    respond_to do |format|
      format.html
      format.json do
        render json: @notes.map { |note|
          points = note.note_points
          {
            id: note.id,
            title: note.title,
            body: note.body,
            order: note.order,
            points_count: points.size,
            checked_count: points.count { |p| p.checked },
            unchecked_points: points.reject(&:checked).first(5).map { |p| { id: p.id, text: p.text } },
            tags: note.note_tags.map { |t| { id: t.id, name: t.name } },
            updated_at: note.updated_at
          }
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: {
          id: @note.id,
          title: @note.title,
          body: @note.body,
          order: @note.order,
          tags: @note.note_tags.map { |t| { id: t.id, name: t.name } },
          points: build_points_tree(@note.root_points.includes(:children))
        }
      end
    end
  end

  def new
    @note = current_user.notes.build
  end

  def create
    @note = current_user.notes.build(note_params)
    respond_to do |format|
      if @note.save
        sync_tags(@note, params[:note][:tag_names]) if params.dig(:note, :tag_names)
        format.html { redirect_to @note }
        format.json { render json: { id: @note.id, title: @note.title, body: @note.body, order: @note.order }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @note.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @note.update(note_params)
        sync_tags(@note, params[:note][:tag_names]) if params.dig(:note, :tag_names)
        format.html { redirect_to @note }
        format.json { render json: { id: @note.id, title: @note.title, body: @note.body, order: @note.order } }
      else
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: @note.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to notes_path }
      format.json { head :no_content }
    end
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :body, :order)
  end

  def sync_tags(note, tag_names_string)
    return if tag_names_string.nil?
    names = tag_names_string.to_s.split(",").map(&:strip).reject(&:blank?)
    tags = names.map do |name|
      current_user.note_tags.find_or_create_by!(name: name)
    end
    note.note_tags = tags
  end

  def build_points_tree(points)
    points.order(:position).map do |point|
      {
        id: point.id,
        text: point.text,
        checked: point.checked,
        position: point.position,
        parent_id: point.parent_id,
        children: build_points_tree(point.children)
      }
    end
  end
end
