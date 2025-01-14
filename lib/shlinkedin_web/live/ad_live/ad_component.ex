defmodule ShlinkedinWeb.AdLive.AdComponent do
  use ShlinkedinWeb, :live_component
  alias Shlinkedin.Ads

  def mount(socket) do
    {:ok, socket |> assign(spin: false)}
  end

  def handle_event("ad-click", %{"id" => id}, socket) do
    ad = Shlinkedin.Ads.get_ad_preload_profile!(id)

    Shlinkedin.Ads.create_ad_click(ad, socket.assigns.profile)

    {:noreply,
     socket |> push_redirect(to: Routes.profile_show_path(socket, :show, ad.profile.slug))}
  end

  def handle_event("censor-ad", _, socket) do
    {:ok, _} = Ads.update_ad(socket.assigns.profile, socket.assigns.ad, %{removed: true})

    {:noreply,
     socket
     |> put_flash(:info, "Ad deleted")
     |> push_redirect(to: Routes.home_index_path(socket, :index))}
  end

  def handle_event(
        "like-selected",
        %{"like-type" => like_type},
        %{assigns: %{profile: profile, ad: ad}} = socket
      ) do
    if Ads.is_first_like_on_ad?(profile, ad) do
      Ads.create_like(socket.assigns.profile, socket.assigns.ad, like_type)

      send_update(ShlinkedinWeb.AdLive.AdComponent,
        id: socket.assigns.id,
        spin: like_type
      )

      send_update_after(
        ShlinkedinWeb.AdLive.AdComponent,
        [id: socket.assigns.id, spin: nil],
        1000
      )

      {:noreply, socket |> assign(ad: Ads.get_ad_preload_profile!(ad.id))}
    else
      Ads.delete_like(profile, ad)
      {:noreply, socket |> assign(ad: Ads.get_ad_preload_profile!(ad.id))}
    end
  end
end
