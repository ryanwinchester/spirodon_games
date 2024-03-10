# defmodule TwitchGameServerWeb.Auth.UserRegistrationLiveTest do
#   use TwitchGameServerWeb.ConnCase, async: true
#
#   import Phoenix.LiveViewTest
#   import TwitchGameServer.AccountsFixtures
#
#   describe "Registration page" do
#     test "renders registration page", %{conn: conn} do
#       {:ok, _lv, html} = live(conn, ~p"/auth/register")
#
#       assert html =~ "Register"
#       assert html =~ "Log in"
#     end
#
#     test "redirects if already logged in", %{conn: conn} do
#       result =
#         conn
#         |> log_in_user(user_fixture())
#         |> live(~p"/auth/register")
#         |> follow_redirect(conn, "/")
#
#       assert {:ok, _conn} = result
#     end
#
#     test "renders errors for invalid data", %{conn: conn} do
#       {:ok, lv, _html} = live(conn, ~p"/auth/register")
#
#       result =
#         lv
#         |> element("#registration_form")
#         |> render_change(
#           user: %{"email" => "with spaces", "display_name" => "a b", "password" => "too short"}
#         )
#
#       assert result =~ "Register"
#       assert result =~ "must have the @ sign and no spaces"
#       assert result =~ "can only be alphanumeric with dash or underscore"
#       assert result =~ "should be at least 12 character"
#     end
#   end
#
#   describe "register user" do
#     test "creates account and logs the user in", %{conn: conn} do
#       {:ok, lv, _html} = live(conn, ~p"/auth/register")
#
#       email = unique_user_email()
#       display_name = valid_user_display_name()
#       form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
#       render_submit(form)
#       conn = follow_trigger_action(form, conn)
#
#       assert redirected_to(conn) == ~p"/"
#
#       # Now do a logged in request and assert on the menu
#       conn = get(conn, "/")
#       response = html_response(conn, 200)
#       assert response =~ display_name
#       assert response =~ "Settings"
#       assert response =~ "Log out"
#     end
#
#     test "renders errors for duplicated email", %{conn: conn} do
#       {:ok, lv, _html} = live(conn, ~p"/auth/register")
#
#       user = user_fixture(%{email: "test@email.com"})
#
#       result =
#         lv
#         |> form("#registration_form",
#           user: %{"email" => user.email, "display_name" => "abc", "password" => "valid_password"}
#         )
#         |> render_submit()
#
#       assert result =~ "has already been taken"
#     end
#   end
#
#   describe "registration navigation" do
#     test "redirects to login page when the Log in button is clicked", %{conn: conn} do
#       {:ok, lv, _html} = live(conn, ~p"/auth/register")
#
#       {:ok, _login_live, login_html} =
#         lv
#         |> element(~s|main a:fl-contains("Sign in")|)
#         |> render_click()
#         |> follow_redirect(conn, ~p"/auth/login")
#
#       assert login_html =~ "Log in"
#     end
#   end
# end
