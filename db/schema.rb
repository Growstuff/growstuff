# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_29_132911) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "category"
    t.string "name"
    t.string "description"
    t.date "due_date"
    t.boolean "finished"
    t.bigint "owner_id"
    t.bigint "garden_id"
    t.bigint "planting_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "likes_count", default: 0
    t.index ["garden_id"], name: "index_activities_on_garden_id"
    t.index ["owner_id"], name: "index_activities_on_owner_id"
    t.index ["planting_id"], name: "index_activities_on_planting_id"
    t.index ["slug"], name: "index_activities_on_slug", unique: true
  end

  create_table "alternate_names", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "crop_id", null: false
    t.integer "creator_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "language"
    t.index ["creator_id"], name: "index_alternate_names_on_creator_id"
    t.index ["crop_id"], name: "index_alternate_names_on_crop_id"
    t.index ["language"], name: "index_alternate_names_on_language"
  end

  create_table "australian_food_classification_data", force: :cascade do |t|
    t.string "public_food_key"
    t.string "classification"
    t.string "food_name"
    t.decimal "energy_with_dietary_fibre_equated_kj"
    t.decimal "energy_without_dietary_fibre_equated_kj"
    t.decimal "moisture_water_g"
    t.decimal "protein_g"
    t.decimal "nitrogen_g"
    t.decimal "fat_total_g"
    t.decimal "ash_g"
    t.decimal "total_dietary_fibre_g"
    t.decimal "alcohol_g"
    t.decimal "fructose_g"
    t.decimal "glucose_g"
    t.decimal "sucrose_g"
    t.decimal "maltose_g"
    t.decimal "lactose_g"
    t.decimal "galactose_g"
    t.decimal "maltotrios_g"
    t.decimal "total_sugars_g"
    t.decimal "added_sugars_g"
    t.decimal "free_sugars_g"
    t.decimal "starch_g"
    t.decimal "dextrin_g"
    t.decimal "glycerol_g"
    t.decimal "glycogen_g"
    t.decimal "inulin_g"
    t.decimal "erythritol_g"
    t.decimal "maltitol_g"
    t.decimal "mannitol_g"
    t.decimal "xylitol_g"
    t.decimal "maltodextrin_g"
    t.decimal "oligosaccharides_g"
    t.decimal "polydextrose_g"
    t.decimal "raffinose_g"
    t.decimal "stachyose_g"
    t.decimal "sorbitol_g"
    t.decimal "resistant_starch_g"
    t.decimal "available_carbohydrate_without_sugar_alcohols_g"
    t.decimal "available_carbohydrate_with_sugar_alcohols_g"
    t.decimal "acetic_acid_g"
    t.decimal "citric_acid_g"
    t.decimal "fumaric_acid_g"
    t.decimal "lactic_acid_g"
    t.decimal "malic_acid_g"
    t.decimal "oxalic_acid_g"
    t.decimal "propionic_acid_g"
    t.decimal "quinic_acid_g"
    t.decimal "shikimic_acid_g"
    t.decimal "succinic_acid_g"
    t.decimal "tartaric_acid_g"
    t.decimal "aluminium_al_ug"
    t.decimal "antimony_sb_ug"
    t.decimal "arsenic_as_ug"
    t.decimal "cadmium_cd_ug"
    t.decimal "calcium_ca_mg"
    t.decimal "chromium_cr_ug"
    t.decimal "chloride_cl_mg"
    t.decimal "cobalt_co_ug"
    t.decimal "copper_cu_mg"
    t.decimal "fluoride_f_ug"
    t.decimal "iodine_i_ug"
    t.decimal "iron_fe_mg"
    t.decimal "lead_pb_ug"
    t.decimal "magnesium_mg_mg"
    t.decimal "manganese_mn_mg"
    t.decimal "mercury_hg_ug"
    t.decimal "molybdenum_mo_ug"
    t.decimal "nickel_ni_ug"
    t.decimal "phosphorus_p_mg"
    t.decimal "potassium_k_mg"
    t.decimal "selenium_se_ug"
    t.decimal "sodium_na_mg"
    t.decimal "sulphur_s_mg"
    t.decimal "tin_sn_ug"
    t.decimal "zinc_zn_mg"
    t.decimal "retinol_preformed_vitamin_a_ug"
    t.decimal "alpha_carotene_ug"
    t.decimal "beta_carotene_ug"
    t.decimal "cryptoxanthin_ug"
    t.decimal "beta_carotene_equivalents_provitamin_a_ug"
    t.decimal "vitamin_a_retinol_equivalents_ug"
    t.decimal "lutein_ug"
    t.decimal "lycopene_ug"
    t.decimal "xanthophyl_ug"
    t.decimal "thiamin_b1_mg"
    t.decimal "riboflavin_b2_mg"
    t.decimal "niacin_b3_mg"
    t.decimal "niacin_derived_from_tryptophan_mg"
    t.decimal "niacin_derived_equivalents_mg"
    t.decimal "pantothenic_acid_b5_mg"
    t.decimal "pyridoxine_b6_mg"
    t.decimal "biotin_b7_ug"
    t.decimal "cobalamin_b12_ug"
    t.decimal "folate_natural_ug"
    t.decimal "folic_acid_ug"
    t.decimal "total_folates_ug"
    t.decimal "dietary_folate_equivalents_ug"
    t.decimal "vitamin_c_mg"
    t.decimal "cholecalciferol_d3_ug"
    t.decimal "ergocalciferol_d2_ug"
    t.decimal "c25_hydroxy_cholecalciferol_25_oh_d3_ug"
    t.decimal "c25_hydroxy_ergocalciferol_25_oh_d2_ug"
    t.decimal "vitamin_d3_equivalents_ug"
    t.decimal "alpha_tocopherol_mg"
    t.decimal "alpha_tocotrienol_mg"
    t.decimal "beta_tocopherol_mg"
    t.decimal "beta_tocotrienol_mg"
    t.decimal "delta_tocopherol_mg"
    t.decimal "delta_tocotrienol_mg"
    t.decimal "gamma_tocopherol_mg"
    t.decimal "gamma_tocotrienol_mg"
    t.decimal "vitamin_e_mg"
    t.decimal "c4_t"
    t.decimal "c6_t"
    t.decimal "c8_t"
    t.decimal "c10_t"
    t.decimal "c11_t"
    t.decimal "c12_t"
    t.decimal "c13_t"
    t.decimal "c14_t"
    t.decimal "c15_t"
    t.decimal "c16_t"
    t.decimal "c17_t"
    t.decimal "c18_t"
    t.decimal "c19_t"
    t.decimal "c20_t"
    t.decimal "c21_t"
    t.decimal "c22_t"
    t.decimal "c23_t"
    t.decimal "c24_t"
    t.decimal "total_saturated_fatty_acids_equated_t"
    t.decimal "c10_1_t"
    t.decimal "c12_1_t"
    t.decimal "c14_1_t"
    t.decimal "c15_1_t"
    t.decimal "c16_1_t"
    t.decimal "c17_1_t"
    t.decimal "c18_1_t"
    t.decimal "c18_1w5_t"
    t.decimal "c18_1w6_t"
    t.decimal "c18_1w7_t"
    t.decimal "c18_1w9_t"
    t.decimal "c20_1_t"
    t.decimal "c20_1w9_t"
    t.decimal "c20_1w13_t"
    t.decimal "c20_1w11_t"
    t.decimal "c22_1_t"
    t.decimal "c22_1w9_t"
    t.decimal "c22_1w11_t"
    t.decimal "c24_1_t"
    t.decimal "c24_1w9_t"
    t.decimal "c24_1w11_t"
    t.decimal "c24_1w13_t"
    t.decimal "total_monounsaturated_fatty_acids_equated_t"
    t.decimal "c12_2_t"
    t.decimal "c16_2w4_t"
    t.decimal "c16_3_t"
    t.decimal "c18_2w6_t"
    t.decimal "c18_3w3_t"
    t.decimal "c18_3w4_t"
    t.decimal "c18_3w6_t"
    t.decimal "c18_4w1_t"
    t.decimal "c18_4w3_t"
    t.decimal "c20_2_t"
    t.decimal "c20_2w6_t"
    t.decimal "c20_3_t"
    t.decimal "c20_4_t"
    t.decimal "c20_3w3_t"
    t.decimal "c20_3w6_t"
    t.decimal "c20_4w3_t"
    t.decimal "c20_4w6_t"
    t.decimal "c20_5w3_t"
    t.decimal "c21_5w3_t"
    t.decimal "c22_2_t"
    t.decimal "c22_2w6_t"
    t.decimal "c22_4w6_t"
    t.decimal "c22_5w3_t"
    t.decimal "c22_5w6_t"
    t.decimal "c22_6w3_t"
    t.decimal "total_polyunsaturated_fatty_acids_equated_t"
    t.decimal "total_long_chain_omega_3_fatty_acids_equated_t"
    t.decimal "total_undifferentiated_fatty_acids_t"
    t.decimal "total_trans_fatty_acids_imputed_t"
    t.decimal "c4_g"
    t.decimal "c6_g"
    t.decimal "c8_g"
    t.decimal "c10_g"
    t.decimal "c11_g"
    t.decimal "c12_g"
    t.decimal "c13_g"
    t.decimal "c14_g"
    t.decimal "c15_g"
    t.decimal "c16_g"
    t.decimal "c17_g"
    t.decimal "c18_g"
    t.decimal "c19_g"
    t.decimal "c20_g"
    t.decimal "c21_g"
    t.decimal "c22_g"
    t.decimal "c23_g"
    t.decimal "c24_g"
    t.decimal "total_saturated_fatty_acids_equated_g"
    t.decimal "c10_1_g"
    t.decimal "c12_1_g"
    t.decimal "c14_1_g"
    t.decimal "c15_1_g"
    t.decimal "c16_1_g"
    t.decimal "c17_1_g"
    t.decimal "c18_1_g"
    t.decimal "c18_1w5_mg"
    t.decimal "c18_1w6_mg"
    t.decimal "c18_1w7_g"
    t.decimal "c18_1w9_mg"
    t.decimal "c20_1_g"
    t.decimal "c20_1w9_mg"
    t.decimal "c20_1w13_mg"
    t.decimal "c20_1w11_mg"
    t.decimal "c22_1_g"
    t.decimal "c22_1w9_mg"
    t.decimal "c22_1w11_mg"
    t.decimal "c24_1_g"
    t.decimal "c24_1w9_mg"
    t.decimal "c24_1w11_mg"
    t.decimal "c24_1w13_mg"
    t.decimal "total_monounsaturated_fatty_acids_equated_g"
    t.decimal "c12_2_g"
    t.decimal "c16_2w4_mg"
    t.decimal "c16_3_g"
    t.decimal "c18_2w6_g"
    t.decimal "c18_3w3_g"
    t.decimal "c18_3w4_g"
    t.decimal "c18_3w6_mg"
    t.decimal "c18_4w1_g"
    t.decimal "c18_4w3_mg"
    t.decimal "c20_2_mg"
    t.decimal "c20_2w6_mg"
    t.decimal "c20_3_mg"
    t.decimal "c20_3w3_mg"
    t.decimal "c20_3w6_mg"
    t.decimal "c20_4_g"
    t.decimal "c20_4w3_mg"
    t.decimal "c20_4w6_mg"
    t.decimal "c20_5w3_mg"
    t.decimal "c21_5w3_g"
    t.decimal "c22_5w3_mg"
    t.decimal "c22_4w6_mg"
    t.decimal "c22_2_g"
    t.decimal "c22_2w6_mg"
    t.decimal "c22_5w6_g"
    t.decimal "c22_6w3_mg"
    t.decimal "total_polyunsaturated_fatty_acids_equated_g"
    t.decimal "total_long_chain_omega_3_fatty_acids_equated_mg"
    t.decimal "total_undifferentiated_fatty_acids_mass_basis_basis_mg"
    t.decimal "total_trans_fatty_acids_imputed_mg"
    t.decimal "caffeine_mg"
    t.decimal "cholesterol_mg"
    t.decimal "alanine_mg_gn"
    t.decimal "arginine_mg_gn"
    t.decimal "aspartic_acid_mg_gn"
    t.decimal "cystine_plus_cysteine_mg_gn"
    t.decimal "glutamic_acid_mg_gn"
    t.decimal "glycine_mg_gn"
    t.decimal "histidine_mg_gn"
    t.decimal "isoleucine_mg_gn"
    t.decimal "leucine_mg_gn"
    t.decimal "lysine_mg_gn"
    t.decimal "methionine_mg_gn"
    t.decimal "phenylalanine_mg_gn"
    t.decimal "proline_mg_gn"
    t.decimal "serine_mg_gn"
    t.decimal "threonine_mg_gn"
    t.decimal "tyrosine_mg_gn"
    t.decimal "tryptophan_mg_gn"
    t.decimal "valine_mg_gn"
    t.decimal "alanine_mg"
    t.decimal "arginine_mg"
    t.decimal "aspartic_acid_mg"
    t.decimal "cystine_plus_cysteine_mg"
    t.decimal "glutamic_acid_mg"
    t.decimal "glycine_mg"
    t.decimal "histidine_mg"
    t.decimal "isoleucine_mg"
    t.decimal "leucine_mg"
    t.decimal "lysine_mg"
    t.decimal "methionine_mg"
    t.decimal "phenylalanine_mg"
    t.decimal "proline_mg"
    t.decimal "serine_mg"
    t.decimal "threonine_mg"
    t.decimal "tyrosine_mg"
    t.decimal "tryptophan_mg"
    t.decimal "valine_mg"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["public_food_key"], name: "index_australian_food_classification_data_on_public_food_key"
  end

  create_table "authentications", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "provider", null: false
    t.string "uid"
    t.string "token"
    t.string "secret"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "name"
    t.index ["member_id"], name: "index_authentications_on_member_id"
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id"
    t.bigint "blocked_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "comfy_cms_categories", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "categorized_type", null: false
    t.index ["site_id", "categorized_type", "label"], name: "index_cms_categories_on_site_id_and_cat_type_and_label", unique: true
  end

  create_table "comfy_cms_categorizations", id: :serial, force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "categorized_type", null: false
    t.integer "categorized_id", null: false
    t.index ["category_id", "categorized_type", "categorized_id"], name: "index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id", unique: true
  end

  create_table "comfy_cms_files", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "block_id"
    t.string "label", default: "", null: false
    t.string "file_file_name"
    t.string "description", limit: 2048
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["site_id", "block_id"], name: "index_comfy_cms_files_on_site_id_and_block_id"
    t.index ["site_id", "file_file_name"], name: "index_comfy_cms_files_on_site_id_and_file_file_name"
    t.index ["site_id", "label"], name: "index_comfy_cms_files_on_site_id_and_label"
    t.index ["site_id", "position"], name: "index_comfy_cms_files_on_site_id_and_position"
  end

  create_table "comfy_cms_fragments", id: :serial, force: :cascade do |t|
    t.string "identifier", null: false
    t.text "content"
    t.string "record_type"
    t.integer "record_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "tag", default: "text", null: false
    t.datetime "datetime", precision: nil
    t.boolean "boolean", default: false, null: false
    t.index ["identifier"], name: "index_comfy_cms_fragments_on_identifier"
    t.index ["record_id", "record_type"], name: "index_comfy_cms_fragments_on_record_id_and_record_type"
  end

  create_table "comfy_cms_layouts", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "parent_id"
    t.string "app_layout"
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.text "css"
    t.text "js"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["parent_id", "position"], name: "index_comfy_cms_layouts_on_parent_id_and_position"
    t.index ["site_id", "identifier"], name: "index_comfy_cms_layouts_on_site_id_and_identifier", unique: true
  end

  create_table "comfy_cms_pages", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "layout_id"
    t.integer "parent_id"
    t.integer "target_page_id"
    t.string "label", null: false
    t.string "slug"
    t.string "full_path", null: false
    t.text "content_cache"
    t.integer "position", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["parent_id", "position"], name: "index_comfy_cms_pages_on_parent_id_and_position"
    t.index ["site_id", "full_path"], name: "index_comfy_cms_pages_on_site_id_and_full_path"
  end

  create_table "comfy_cms_revisions", id: :serial, force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.text "data"
    t.datetime "created_at", precision: nil
    t.index ["record_type", "record_id", "created_at"], name: "index_cms_revisions_on_rtype_and_rid_and_created_at"
  end

  create_table "comfy_cms_sites", id: :serial, force: :cascade do |t|
    t.string "label", null: false
    t.string "identifier", null: false
    t.string "hostname", null: false
    t.string "path"
    t.string "locale", default: "en", null: false
    t.index ["hostname"], name: "index_comfy_cms_sites_on_hostname"
  end

  create_table "comfy_cms_snippets", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["site_id", "identifier"], name: "index_comfy_cms_snippets_on_site_id_and_identifier", unique: true
    t.index ["site_id", "position"], name: "index_comfy_cms_snippets_on_site_id_and_position"
  end

  create_table "comfy_cms_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.integer "page_id", null: false
    t.integer "layout_id"
    t.string "label", null: false
    t.text "content_cache"
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["is_published"], name: "index_comfy_cms_translations_on_is_published"
    t.index ["locale"], name: "index_comfy_cms_translations_on_locale"
    t.index ["page_id"], name: "index_comfy_cms_translations_on_page_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "commentable_id", null: false
    t.integer "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "commentable_type"
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
  end

  create_table "crop_companions", force: :cascade do |t|
    t.integer "crop_a_id", null: false
    t.integer "crop_b_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "source_url"
    t.index ["crop_a_id", "crop_b_id"], name: "index_crop_companions_on_crop_a_id_and_crop_b_id"
  end

  create_table "crop_posts", id: false, force: :cascade do |t|
    t.integer "crop_id"
    t.integer "post_id"
    t.index ["crop_id", "post_id"], name: "index_crop_posts_on_crop_id_and_post_id"
    t.index ["crop_id"], name: "index_crop_posts_on_crop_id"
  end

  create_table "crops", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "en_wikipedia_url"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.integer "parent_id"
    t.integer "plantings_count", default: 0
    t.integer "creator_id"
    t.integer "requester_id"
    t.string "approval_status", default: "approved"
    t.text "reason_for_rejection"
    t.text "request_notes"
    t.text "rejection_notes"
    t.boolean "perennial", default: false
    t.integer "median_lifespan"
    t.integer "median_days_to_first_harvest"
    t.integer "median_days_to_last_harvest"
    t.jsonb "openfarm_data"
    t.integer "harvests_count", default: 0
    t.integer "photo_associations_count", default: 0
    t.integer "row_spacing"
    t.integer "spread"
    t.integer "height"
    t.string "sowing_method"
    t.string "sun_requirements"
    t.integer "growing_degree_days"
    t.string "en_youtube_url"
    t.text "description"
    t.string "public_food_key"
    t.index ["creator_id"], name: "index_crops_on_creator_id"
    t.index ["name"], name: "index_crops_on_name"
    t.index ["parent_id"], name: "index_crops_on_parent_id"
    t.index ["public_food_key"], name: "index_crops_on_public_food_key"
    t.index ["requester_id"], name: "index_crops_on_requester_id"
    t.index ["slug"], name: "index_crops_on_slug", unique: true
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id"
  end

  create_table "forums", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.integer "owner_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.index ["owner_id"], name: "index_forums_on_owner_id"
    t.index ["slug"], name: "index_forums_on_slug", unique: true
  end

  create_table "garden_collaborators", force: :cascade do |t|
    t.bigint "member_id"
    t.bigint "garden_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["garden_id"], name: "index_garden_collaborators_on_garden_id"
    t.index ["member_id", "garden_id"], name: "index_garden_collaborators_on_member_id_and_garden_id", unique: true
    t.index ["member_id"], name: "index_garden_collaborators_on_member_id"
  end

  create_table "garden_types", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_garden_types_on_name", unique: true
    t.index ["slug"], name: "index_garden_types_on_slug", unique: true
  end

  create_table "gardens", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "owner_id"
    t.string "slug", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "description"
    t.boolean "active", default: true
    t.string "location"
    t.float "latitude"
    t.float "longitude"
    t.decimal "area"
    t.string "area_unit"
    t.integer "garden_type_id"
    t.string "location_wikidata_id"
    t.float "lowest_temp_c"
    t.float "highest_temp_c"
    t.index ["garden_type_id"], name: "index_gardens_on_garden_type_id"
    t.index ["owner_id"], name: "index_gardens_on_owner_id"
    t.index ["slug"], name: "index_gardens_on_slug", unique: true
  end

  create_table "gardens_photos", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "garden_id"
    t.index ["garden_id", "photo_id"], name: "index_gardens_photos_on_garden_id_and_photo_id"
  end

  create_table "harvests", id: :serial, force: :cascade do |t|
    t.integer "crop_id", null: false
    t.integer "owner_id", null: false
    t.date "harvested_at"
    t.decimal "quantity"
    t.string "unit"
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.decimal "weight_quantity"
    t.string "weight_unit"
    t.integer "plant_part_id"
    t.float "si_weight"
    t.integer "planting_id"
    t.integer "likes_count", default: 0
    t.index ["crop_id"], name: "index_harvests_on_crop_id"
    t.index ["owner_id"], name: "index_harvests_on_owner_id"
    t.index ["plant_part_id"], name: "index_harvests_on_plant_part_id"
    t.index ["planting_id"], name: "index_harvests_on_planting_id"
  end

  create_table "harvests_photos", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "harvest_id"
    t.index ["harvest_id", "photo_id"], name: "index_harvests_photos_on_harvest_id_and_photo_id"
  end

  create_table "likes", id: :serial, force: :cascade do |t|
    t.integer "member_id"
    t.string "likeable_type"
    t.integer "likeable_id"
    t.string "categories", array: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["likeable_id"], name: "index_likes_on_likeable_id"
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable_type_and_likeable_id"
    t.index ["member_id"], name: "index_likes_on_member_id"
  end

  create_table "mailboxer_conversation_opt_outs", id: :serial, force: :cascade do |t|
    t.string "unsubscriber_type"
    t.integer "unsubscriber_id"
    t.integer "conversation_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["conversation_id"], name: "index_mailboxer_conversation_opt_outs_on_conversation_id"
    t.index ["unsubscriber_id", "unsubscriber_type"], name: "index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type"
  end

  create_table "mailboxer_conversations", id: :serial, force: :cascade do |t|
    t.string "subject", default: ""
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "mailboxer_notifications", id: :serial, force: :cascade do |t|
    t.string "type"
    t.text "body"
    t.string "subject", default: ""
    t.string "sender_type"
    t.integer "sender_id"
    t.integer "conversation_id"
    t.boolean "draft", default: false
    t.string "notification_code"
    t.string "notified_object_type"
    t.integer "notified_object_id"
    t.string "attachment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "global", default: false
    t.datetime "expires", precision: nil
    t.index ["conversation_id"], name: "index_mailboxer_notifications_on_conversation_id"
    t.index ["notified_object_id", "notified_object_type"], name: "index_mailboxer_notifications_on_notified_object_id_and_type"
    t.index ["notified_object_type", "notified_object_id"], name: "mailboxer_notifications_notified_object"
    t.index ["sender_id", "sender_type"], name: "index_mailboxer_notifications_on_sender_id_and_sender_type"
    t.index ["type"], name: "index_mailboxer_notifications_on_type"
  end

  create_table "mailboxer_receipts", id: :serial, force: :cascade do |t|
    t.string "receiver_type"
    t.integer "receiver_id"
    t.integer "notification_id", null: false
    t.boolean "is_read", default: false
    t.boolean "trashed", default: false
    t.boolean "deleted", default: false
    t.string "mailbox_type", limit: 25
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_delivered", default: false
    t.string "delivery_method"
    t.string "message_id"
    t.index ["notification_id"], name: "index_mailboxer_receipts_on_notification_id"
    t.index ["receiver_id", "receiver_type"], name: "index_mailboxer_receipts_on_receiver_id_and_receiver_type"
  end

  create_table "median_functions", id: :serial, force: :cascade do |t|
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "login_name"
    t.string "slug"
    t.boolean "tos_agreement"
    t.boolean "show_email"
    t.string "location"
    t.float "latitude"
    t.float "longitude"
    t.boolean "send_notification_email", default: true
    t.text "bio"
    t.integer "plantings_count"
    t.boolean "newsletter"
    t.boolean "send_planting_reminder", default: true
    t.string "preferred_avatar_uri"
    t.integer "gardens_count"
    t.integer "harvests_count"
    t.integer "seeds_count"
    t.datetime "discarded_at", precision: nil
    t.integer "photos_count"
    t.integer "forums_count"
    t.integer "activities_count"
    t.string "website_url"
    t.string "instagram_handle"
    t.string "facebook_handle"
    t.string "bluesky_handle"
    t.string "other_url"
    t.boolean "send_harvest_reminder", default: true, null: false
    t.index ["confirmation_token"], name: "index_members_on_confirmation_token", unique: true
    t.index ["discarded_at"], name: "index_members_on_discarded_at"
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_members_on_slug", unique: true
    t.index ["unlock_token"], name: "index_members_on_unlock_token", unique: true
  end

  create_table "members_roles", id: false, force: :cascade do |t|
    t.integer "member_id"
    t.integer "role_id"
    t.index ["member_id", "role_id"], name: "index_members_roles_on_member_id_and_role_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "sender_id"
    t.integer "recipient_id", null: false
    t.string "subject"
    t.text "body"
    t.boolean "read", default: false
    t.integer "notifiable_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "notifiable_type"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["sender_id"], name: "index_notifications_on_sender_id"
  end

  create_table "orders_products", id: false, force: :cascade do |t|
    t.integer "order_id"
    t.integer "product_id"
    t.index ["order_id", "product_id"], name: "index_orders_products_on_order_id_and_product_id"
  end

  create_table "photo_associations", id: :serial, force: :cascade do |t|
    t.integer "photo_id", null: false
    t.integer "photographable_id", null: false
    t.string "photographable_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "crop_id"
    t.index ["crop_id"], name: "index_photo_associations_on_crop_id"
    t.index ["photographable_id", "photographable_type", "photo_id"], name: "items_to_photos_idx", unique: true
    t.index ["photographable_id", "photographable_type"], name: "photographable_idx"
  end

  create_table "photos", id: :serial, force: :cascade do |t|
    t.integer "owner_id", null: false
    t.string "thumbnail_url", null: false
    t.string "fullsize_url", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "title", null: false
    t.string "license_name", null: false
    t.string "license_url"
    t.string "link_url", null: false
    t.string "source_id"
    t.datetime "date_taken", precision: nil
    t.integer "likes_count", default: 0
    t.string "source"
    t.integer "comments_count", default: 0
    t.index ["fullsize_url"], name: "index_photos_on_fullsize_url", unique: true
    t.index ["owner_id"], name: "index_photos_on_owner_id"
    t.index ["source_id"], name: "index_photos_on_source_id"
    t.index ["thumbnail_url"], name: "index_photos_on_thumbnail_url", unique: true
  end

  create_table "photos_plantings", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "planting_id"
    t.index ["photo_id", "planting_id"], name: "index_photos_plantings_on_photo_id_and_planting_id"
  end

  create_table "photos_seeds", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "seed_id"
    t.index ["seed_id", "photo_id"], name: "index_photos_seeds_on_seed_id_and_photo_id"
  end

  create_table "plant_parts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.integer "harvests_count", default: 0
    t.index ["slug"], name: "index_plant_parts_on_slug", unique: true
  end

  create_table "plantings", id: :serial, force: :cascade do |t|
    t.integer "garden_id", null: false
    t.integer "crop_id", null: false
    t.date "planted_at"
    t.integer "quantity"
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.string "sunniness"
    t.string "planted_from"
    t.integer "owner_id"
    t.boolean "finished", default: false, null: false
    t.date "finished_at"
    t.integer "lifespan"
    t.integer "days_to_first_harvest"
    t.integer "days_to_last_harvest"
    t.integer "parent_seed_id"
    t.integer "harvests_count", default: 0
    t.integer "likes_count", default: 0
    t.boolean "failed", default: false, null: false
    t.boolean "from_other_source"
    t.integer "overall_rating"
    t.index ["crop_id"], name: "index_plantings_on_crop_id"
    t.index ["garden_id"], name: "index_plantings_on_garden_id"
    t.index ["owner_id"], name: "index_plantings_on_owner_id"
    t.index ["parent_seed_id"], name: "index_plantings_on_parent_seed_id"
    t.index ["slug"], name: "index_plantings_on_slug", unique: true
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.integer "forum_id"
    t.integer "likes_count", default: 0
    t.integer "comments_count", default: 0
    t.index ["created_at", "author_id"], name: "index_posts_on_created_at_and_author_id"
    t.index ["forum_id"], name: "index_posts_on_forum_id"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.index ["slug"], name: "index_roles_on_slug", unique: true
  end

  create_table "scientific_names", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "crop_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "creator_id"
    t.integer "gbif_key"
    t.string "gbif_rank"
    t.string "gbif_status"
    t.string "wikidata_id"
    t.index ["creator_id"], name: "index_scientific_names_on_creator_id"
    t.index ["crop_id"], name: "index_scientific_names_on_crop_id"
  end

  create_table "seeds", id: :serial, force: :cascade do |t|
    t.integer "owner_id", null: false
    t.integer "crop_id", null: false
    t.text "description"
    t.integer "quantity"
    t.date "plant_before"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "tradable_to", default: "nowhere"
    t.string "slug"
    t.integer "days_until_maturity_min"
    t.integer "days_until_maturity_max"
    t.text "organic", default: "unknown"
    t.text "gmo", default: "unknown"
    t.text "heirloom", default: "unknown"
    t.boolean "finished", default: false
    t.date "finished_at"
    t.integer "parent_planting_id"
    t.date "saved_at"
    t.string "source"
    t.index ["crop_id"], name: "index_seeds_on_crop_id"
    t.index ["owner_id"], name: "index_seeds_on_owner_id"
    t.index ["parent_planting_id"], name: "index_seeds_on_parent_planting_id"
    t.index ["slug"], name: "index_seeds_on_slug", unique: true
    t.index ["source"], name: "index_seeds_on_source"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "members", column: "blocked_id"
  add_foreign_key "blocks", "members", column: "blocker_id"
  add_foreign_key "harvests", "plantings"
  add_foreign_key "mailboxer_conversation_opt_outs", "mailboxer_conversations", column: "conversation_id", name: "mb_opt_outs_on_conversations_id"
  add_foreign_key "mailboxer_notifications", "mailboxer_conversations", column: "conversation_id", name: "notifications_on_conversation_id"
  add_foreign_key "mailboxer_receipts", "mailboxer_notifications", column: "notification_id", name: "receipts_on_notification_id"
  add_foreign_key "photo_associations", "crops"
  add_foreign_key "photo_associations", "photos"
  add_foreign_key "plantings", "seeds", column: "parent_seed_id", name: "parent_seed", on_delete: :nullify
  add_foreign_key "seeds", "plantings", column: "parent_planting_id", name: "parent_planting", on_delete: :nullify
end
