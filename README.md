# KPS-iOS
KPS iOS SDK

# API

---

## Setup

---

#### Init

Init the KPS SDK. Please init the SDK before calling any KPS API, preferably at the app startup.

```
//init function
```

---

## User
---
#### Login

Login A KPS user and build a session with the KPS server

```
fun KPS.login(keyId: String, token: String, callback: (errMsg: String?, kpsUser: KPSUser?, isNew: Boolean) -> Unit)
```
- keyId: The key ID for signing the jwt token
- token: A jwt token containing user information signed by the private key of keyId

**Return:**
- errMsg: error message. Null if everything is correct
- kpsUser: The logged in user
- isNew: indicating the user being logged in is newly created or not
---

#### Logout

Logout A KPS user and clear the session

```
fun KPS.logout(callback: (errMsg: String?) -> Unit)
```

**Return:**
- errMsg: error message. Null if everything is correct
---

#### Check Login Status

Check current user login status

```
fun KPS.isLoggedIn(): Boolean
```

**Return:**
The function return whether the a user has logged in or not. **Note:** the result reflects only local status and might not be accurate if the session has been cancelled remotely.
---


## Content
---

#### Get Content List

Retreive the content

```
fun KPS.openKPSContent(contentId: String?, callback: (errMsg: String?, kpsContent: KPSContent?, children: List<KPSContent>?, orderChildrenIncreaseRight: Boolean) -> Unit)
```
- ContentId: The id of the content to be retreived. Input null for root children.

**Return:**
- errMsg: error message. Null if everything is correct
- kpsContent: The content being asked for
- children: The child content of the returned content
- orderChildrenIncreaseRight: indicating whether children should be arranged left-to-right or right-to-left.

---

## UI
---

#### Display Content List View

Open a new activity to show the default content list view

```
fun KPS.openKPSContentUI(activity: Activity, id: String?)
```

- activity: current activity for listening for onActivityResult callback
- id: The id of the content to be opened. Input null for root children.

---

#### Display Article View

Open a new activity to show the article view

```
fun KPS.openKPSArticleUI(activity: Activity, folderId: String, selectedAid: String) {
```

- activity: current activity for listening for onActivityResult callback
- folderId: The parent folder id of the opening article. Input null for root folder.
- selectedAid: The id of the opening article.

---


# Model
---

## User
---

#### KPSUser

```
data class KPSUser {
    public val id: String
}
```

- id: unique user id
---

## Content
---

#### KPSContent

```
data class KPSContent {
    public val id: String,
    public val type: String,
    public val name: String,
    public val description: String,
    public val customData: JSONObject?,
    public val images: ArrayList<KPSImage>
}
```

- id: content id
- type: content type, could be used to determine what ui to use
- name: content name
- description: content description
- images: content images
- customData: special custom data from publishing, if any.
---

#### KPSImage

```
data class KPSImage {
    public val width: Int,
    public val height: Int,
    fun getUri(targetWidth: Int): String
}
```

- width: origin image width
- height: origin image height
- getUri: a method returning the uri for the thumbnail for the targetWidth
