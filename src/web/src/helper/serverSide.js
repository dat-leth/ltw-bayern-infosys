export const serverSideRendering = () => process.env.NEXT_PUBLIC_SERVER_SIDE != null;

export const clientSideRendering = () => process.env.NEXT_PUBLIC_SERVER_SIDE == null;

export async function loadData(path, setter) {
    // client side rendering + setter => call from useEvent hook
    if (clientSideRendering() && setter) {
        const data = await fetchData(path);
        if (data != null) {
            setter(data);
        }

        return;
    }

    // client side rendering + no setter => call from preloading function
    if (clientSideRendering() && !setter) {
        return {props: {}};
    }

    // server side rendering + no setter => call from preloading function
    if (serverSideRendering() && !setter) {
        const data = await fetchData(path);
        if (data != null) {
            return {props: {data}}
        } else {
            return {
                notFound: true,
            };
        }
    }
}

async function fetchData(path) {
    const resp = await fetch(process.env.NEXT_PUBLIC_BACKEND_URL + path);

    if (resp.ok) {
        return await resp.json();
    } else {
        console.warn('Backend Request not successful', resp);
    }
}